#!/usr/bin/env python3
import base64, os, time
import jwt, requests

API='https://api.appstoreconnect.apple.com'
APP_ID=os.environ['ASC_APP_ID']
VERSION=os.environ.get('ASC_VERSION','1.0.0')
KEY_ID=os.environ['ASC_KEY_ID']
ISSUER_ID=os.environ['ASC_ISSUER_ID']
KEY=base64.b64decode(os.environ['ASC_API_KEY_BASE64']).decode('utf-8')
now=int(time.time())
TOKEN=jwt.encode({'iss':ISSUER_ID,'iat':now,'exp':now+900,'aud':'appstoreconnect-v1'},KEY,algorithm='ES256',headers={'kid':KEY_ID,'typ':'JWT'})
H={'Authorization':f'Bearer {TOKEN}','Content-Type':'application/json'}

def api(method,path,**kwargs):
    r=requests.request(method,API+path,headers=H,timeout=60,**kwargs)
    if r.status_code not in (200,201,204):
        raise RuntimeError(f'{method} {path} -> {r.status_code}: {r.text[:1600]}')
    return None if r.status_code==204 else r.json()

def first(path,params=None):
    d=api('GET',path,params=params).get('data',[])
    return d[0] if d else None

app_info=first(f'/v1/apps/{APP_ID}/appInfos',{'limit':10})
if not app_info: raise RuntimeError('App Info missing')
info_id=app_info['id']
version=first(f'/v1/apps/{APP_ID}/appStoreVersions',{'filter[platform]':'IOS','filter[versionString]':VERSION,'limit':10})
if not version: raise RuntimeError(f'App Store version {VERSION} missing')
version_id=version['id']

existing_info={x['attributes']['locale']:x for x in api('GET',f'/v1/appInfos/{info_id}/appInfoLocalizations',params={'limit':200}).get('data',[])}
existing_ver={x['attributes']['locale']:x for x in api('GET',f'/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations',params={'limit':200}).get('data',[])}

for locale in ('en-US','fr-FR'):
    if locale not in existing_info:
        api('POST','/v1/appInfoLocalizations',json={'data':{'type':'appInfoLocalizations','attributes':{'locale':locale,'name':'PowderRunbook'},'relationships':{'appInfo':{'data':{'type':'appInfos','id':info_id}}}}})
        print('CREATED appInfoLocalization',locale)
    else: print('EXISTS appInfoLocalization',locale)
    if locale not in existing_ver:
        api('POST','/v1/appStoreVersionLocalizations',json={'data':{'type':'appStoreVersionLocalizations','attributes':{'locale':locale},'relationships':{'appStoreVersion':{'data':{'type':'appStoreVersions','id':version_id}}}}})
        print('CREATED appStoreVersionLocalization',locale)
    else: print('EXISTS appStoreVersionLocalization',locale)
print('LOCALIZATIONS_READY')
