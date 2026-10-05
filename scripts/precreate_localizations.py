#!/usr/bin/env python3
import base64, os, time
import jwt, requests

API='https://api.appstoreconnect.apple.com'
APP_ID=os.environ['ASC_APP_ID']; VERSION=os.environ.get('ASC_VERSION','1.0.0')
KEY_ID=os.environ['ASC_KEY_ID']; ISSUER_ID=os.environ['ASC_ISSUER_ID']
KEY=base64.b64decode(os.environ['ASC_API_KEY_BASE64']).decode('utf-8')
now=int(time.time())
TOKEN=jwt.encode({'iss':ISSUER_ID,'iat':now,'exp':now+900,'aud':'appstoreconnect-v1'},KEY,algorithm='ES256',headers={'kid':KEY_ID,'typ':'JWT'})
H={'Authorization':f'Bearer {TOKEN}','Content-Type':'application/json'}

def req(method,path,ok=(200,201,204),**kwargs):
    r=requests.request(method,API+path,headers=H,timeout=60,**kwargs)
    if r.status_code not in ok:
        raise RuntimeError(f'{method} {path} -> {r.status_code}: {r.text[:1600]}')
    return r

def data(path,params=None): return req('GET',path,params=params).json().get('data',[])
def first(path,params=None):
    d=data(path,params); return d[0] if d else None

def create_tolerant(path,payload,label):
    r=requests.post(API+path,headers=H,json=payload,timeout=60)
    if r.status_code in (200,201,204):
        print('CREATED',label); return
    if r.status_code==409 and 'ATTRIBUTE.INVALID.DUPLICATE' in r.text:
        print('EXISTS',label,'(duplicate confirmed)'); return
    raise RuntimeError(f'POST {path} -> {r.status_code}: {r.text[:1600]}')

def wait_locale(path,locale,seconds=30):
    end=time.time()+seconds
    while time.time()<end:
        locales={x.get('attributes',{}).get('locale') for x in data(path,{'limit':200})}
        if locale in locales: return
        time.sleep(2)
    print('WARN locale not visible yet after polling:',locale,path)

app_info=first(f'/v1/apps/{APP_ID}/appInfos',{'limit':10})
if not app_info: raise RuntimeError('App Info missing')
info_id=app_info['id']
version=first(f'/v1/apps/{APP_ID}/appStoreVersions',{'filter[platform]':'IOS','filter[versionString]':VERSION,'limit':10})
if not version: raise RuntimeError(f'App Store version {VERSION} missing')
version_id=version['id']

for locale in ('en-US','fr-FR'):
    info_path=f'/v1/appInfos/{info_id}/appInfoLocalizations'
    ver_path=f'/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations'
    info_locales={x['attributes']['locale'] for x in data(info_path,{'limit':200})}
    if locale not in info_locales:
        create_tolerant('/v1/appInfoLocalizations',{'data':{'type':'appInfoLocalizations','attributes':{'locale':locale,'name':'PowderRunbook'},'relationships':{'appInfo':{'data':{'type':'appInfos','id':info_id}}}}},f'appInfoLocalization {locale}')
    else: print('EXISTS appInfoLocalization',locale)
    wait_locale(info_path,locale)

    ver_locales={x['attributes']['locale'] for x in data(ver_path,{'limit':200})}
    if locale not in ver_locales:
        create_tolerant('/v1/appStoreVersionLocalizations',{'data':{'type':'appStoreVersionLocalizations','attributes':{'locale':locale},'relationships':{'appStoreVersion':{'data':{'type':'appStoreVersions','id':version_id}}}}},f'appStoreVersionLocalization {locale}')
    else: print('EXISTS appStoreVersionLocalization',locale)
    wait_locale(ver_path,locale)
print('LOCALIZATIONS_READY')
