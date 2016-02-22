'
'   This document contains configuration information for reuse. All common data
'   should be entered here to avoid needing numerous code changes upon code modification.
'   @author: Hayden McParlane
'   @creation-date: 2.18.2016

Function Username() as String
    return "umkcsce"
End Function

Function RawPassword() as String
    return "123456789"
End Function

Function Password() as String
    return Sha1Digest(RawPassword())
End Function

Function SSLCertificatePath() as String
    return "common:/certs/ca-bundle.crt"
End Function

Function XRokuReservedDevId() as String    
    return ""
End Function
