#############################################################
#	Module for interacting with external APIs from which
#	data is collected and processed.
#	@author: Hayden McParlane
#	@creation-date: 4.22.2016
#   @description: 
#        The collector is responsible for collecting data from some source
#        to be processed and/or used by the server.
#############################################################
from schedules import config as CONFIG
from schedules.server.external.host import HostType as HTYPE
from schedules.server.external.host import HostFactory as HFACTORY
import schedules.server.external.host as HOST
from scram import helper as HELPER
from enum import Enum as ENUM

# TODO: HIGH For decreased coupling and increased cohesion, system should not use
# requests to access image URLs or anything in this module. This should be moved
# to host.Service. It's here for presentation I'm giving tomorrow demonstrating
# application.
import requests as REQ

DATASTORE = CONFIG.DATASTORE

_SD = "SchedulesDirect"

class Collector(object):
    '''Contract which must be adhered to by all collection objects'''
    def __init__(self):
        super(object, self).__init__()
        
    def collect(self, **kwargs):
        raise NotImplementedError()            
        
class SchedulesDirectCollector(Collector):
    _MAX_REQUESTS = 490    
    
    def __init__(self):
        super(Collector, self).__init__()
        self.client = HFACTORY.get(HTYPE.SCHEDULES_DIRECT)        
        self.client.register(self._filter_stationID, HOST.Services.GET_CHANNELS)
        self.client.register(self._filter_programID, HOST.Services.GET_CHANNEL_INFO)
        self.client.register(self._adapter_episodes, HOST.Services.GET_EPISODES)
        self.client.register(self._adapter_grab_image_info, HOST.Services.GET_SERIES_METADATA)        
        self.store = DATASTORE()
        # self.client.register(self._adapter_series, HOST.Services.GET_SERIES_INFO)
        # self.client.register(self._adapter_episodes, HOST.Services.GET_EPISODES)
        
    def collect(self, **kwargs):
        # TODO: HIGH call to series corresponds to lengthy paragraph sent by
        # sched. dir. from program_description. The episode info comes first
        # in the request sequence.        
        channel_ids = self.client.consume(HOST.Services.GET_CHANNELS)        
        episode_shard1, program_ids = self.client.consume(HOST.Services.GET_CHANNEL_INFO, channel_ids)                
        episode_shard2 = self.client.consume(HOST.Services.GET_EPISODES, program_ids)
        series_info = self.client.consume(HOST.Services.GET_SERIES_INFO, program_ids)
        episode_shard3 = self.client.consume(HOST.Services.GET_SERIES_METADATA, program_ids)        
        # TODO: Make sure  all episodes are included otherwise if episode_shard1.size not equal
        # to episode_shard2 then episodes will be left out. 
        #Combine episode objects
        # TODO: All of this logic needs to be refined to be more maintainable and
        # flexible, separation of concerns
        count = 1
        episodes = dict()
        for key, value in episode_shard1.items():            
            episode_shard1[key].update(episode_shard2[key])
            episode_shard1[key].update(episode_shard3[key])            
            episode = episode_shard1[key]
            if count > 0:
                print(episode)
                count-=1            
            self.store.insert("streak", 'episodes', data=episode)

    # TODO: HIGH Use adapters to process data, add default hash filters (i.e,
    # genre, show time, etc) and store processed data.
    
    def _filter_stationID(self, json):        
        stations = list()
        count = self._MAX_REQUESTS          
        for station in json['map']:
            if count > 0:
                sid = station['stationID']
                stations.append({ 'stationID': sid})
                count -= 1
            else:
                break        
        return stations
    
    def _filter_programID(self, json):
        programs = list()
        count = self._MAX_REQUESTS
        episodes = dict()
        for station in json:
            for program in station['programs']:
                if count > 0:
                    # TODO: HIGH Find way to map keys to one another so that
                    # mapping isn't hard coded and can be reused.
                    episode = dict()       
                    
                    # Required fields
                    # TODO: MID Construct hashing system to allow for application of obvious
                    # filters such as by channel, time, genre, etc.
                    episode['contenttype'] = "episode"
                    episode['channelID'] = station['stationID']
                    episode['programID'] = program['programID']
                    episode['channel_md5'] = program['md5']
                    
                    # Optional fields
                    episode['length'] = HELPER.value(program, 'duration')
                    episode['audioProperties'] = HELPER.value(program, 'audioProperties')
                    episode['videoProperties'] = HELPER.value(program, 'videoProperties')
                    #episode['new'] = program['new'] or "None"
                    episode['releasedate'] = HELPER.value(program, 'airDateTime')                    
                    
                    episodes[program['programID']] = episode
                    
                    # Process program for next request
                    programs.append(program['programID'])
                    count -= 1
                else:
                    break             
        # TODO: HIGH Append to episode object        
        return ( episodes, programs )
    
    def _adapter_episodes(self, json):
        episodes = dict()
        count = 5
        for ep in json:
            # TODO: Remove if False stmt. DEBUG purposes
            if False: #count >= 1:
                count -= 1
                print(ep['descriptions'])
            episode = dict()       
            keys = ['titles', 0, 'title']                 
            title = HELPER.getvalue(ep, keys, verbatim=False)                        
            keys = ['episodetitle']            
            eptitle = HELPER.getvalue(ep, keys, verbatim=False)
            episode['title'] = title
            episode['type'] = HELPER.value(ep, 'eventDetails')            
            keys = ['descriptions', 'description', 0]
            description = HELPER.getvalue(ep, keys, verbatim=False)
            if description is not None:
                episode['description'] = HELPER.value(description, 'description')
            else:
                episode['description'] = "None"
            episode['shortdescriptionline1'] = eptitle
            snum = HELPER.getvalue(ep, ['metadata', 0, 'Gracenote', 'season'], verbatim=False)
            epnum = HELPER.getvalue(ep, ['metadata', 0, 'Gracenote', 'episode'], verbatim=False)            
            episode['releasedate'] = HELPER.value(ep, 'originalAirDate')
            episode['actors'] = list()
            if HELPER.has_key(ep, 'cast'):
                for actor in ep['cast']:
                    episode['actors'].append(actor['name'])
            if HELPER.has_key(ep, 'crew'):
                episode['director'] = ep['crew'][0]['name']
            if HELPER.has_key(ep, 'hasImageArtwork'):
                episode['hasimageartwork'] = ep['hasImageArtwork']
            episode['episode_md5'] = ep['md5']
            episodes[ep['programID']] = episode
        return episodes
    
    def _adapter_series(self, json):
        pass
    
    def _adapter_grab_image_info(self, json):
        episodes = dict()
        count = 1
        for ep in json:
            episode = dict()
            
            if count > 0:
                print(ep)
                count -= 1
            
            if HELPER.has_key(ep, 'data'):
                data = HELPER.getvalue(ep, ['data'], verbatim=False)
                if data is not None:
                    for entry in data:                      
                        if 'size' in entry.keys():
                            if 'sm' in entry['size'].lower():
                                episode['sdposterurl'] = entry['uri']
                            if 'lg' in entry['size'].lower():
                                episode['hdposterurl'] = entry['uri']
                            if HELPER.has_key(episode, 'sdposterurl'):                                
                                if 'http' not in episode['sdposterurl'].lower():
                                    # This case means schedules direct should be referenced
                                    # according to schedules JSON API spec
                                    episode['sdposterurl'] = 'https://json.schedulesdirect.org/20141201/image/' + episode['sdposterurl']
                            if HELPER.has_key(episode, 'hdposterurl'):                                
                                if 'http' not in episode['hdposterurl'].lower():
                                    # This case means schedules direct should be referenced
                                    # according to schedules JSON API spec
                                    episode['hdposterurl'] = 'https://json.schedulesdirect.org/20141201/image/' + episode['hdposterurl']
                                episodes[ep['programID']] = episode
                        else:
                            continue
        return episodes
        
def main():
    coll = SchedulesDirectCollector()
    coll.collect()
        
if __name__=="__main__":
    main()
