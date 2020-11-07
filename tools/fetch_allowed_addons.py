#!/usr/bin/env python3

import urllib.request
import json
import base64
import sys

def fetch(x):
  with urllib.request.urlopen(x) as response:
    return response.read()

def find_addon(addons, addon_id):
  results = addons['results']
  for x in results:
    addon = x['addon']
    if addon['guid'] == addon_id:
      return addon
  sys.exit("Error: cannot find addon " + addon_id)

def fetch_and_embed_icons(addons):
  results = addons['results']
  for x in results:
    addon = x['addon']
    icon_data = fetch(addon['icon_url'])
    addon['icon_url'] = 'data:image/png;base64,' + str(base64.b64encode(icon_data), 'utf8')

def patch_https_everywhere(addons):
  addon = find_addon(addons, 'https-everywhere@eff.org')
  addon['guid'] = 'https-everywhere-eff@eff.org'
  addon['url'] = 'https://www.eff.org/https-everywhere'

def main(argv):
  amo_collection = argv[0] if argv else '83a9cccfe6e24a34bd7b155ff9ee32'
  url = 'https://addons.mozilla.org/api/v4/accounts/account/mozilla/collections/' + amo_collection + '/addons/'
  data = json.loads(fetch(url))
  fetch_and_embed_icons(data)
  patch_https_everywhere(data)
  data['results'].sort(key=lambda x: x['addon']['guid'])
  find_addon(data, '{73a6fe31-595d-460b-a920-fcc0f8843232}') # Check that NoScript is present
  print(json.dumps(data, indent=2, ensure_ascii=False))

if __name__ == "__main__":
   main(sys.argv[1:])
