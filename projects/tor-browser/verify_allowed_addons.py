#!/usr/bin/env python

import json
import sys
import hashlib
import zipfile

def find_addon(addons, addon_id):
  results = addons['results']
  for x in results:
    addon = x['addon']
    if addon['guid'] == addon_id:
      return addon
  sys.exit("Error: cannot find addon " + addon_id)

def verify_extension_version(addons, addon_id, version):
  addon = find_addon(addons, addon_id)
  expected_version = addon['current_version']['version']
  if version != expected_version:
    sys.exit("Error: version " + version + " != " + expected_version)

def verify_extension_hash(addons, addon_id, hash):
  addon = find_addon(addons, addon_id)
  expected_hash = addon["current_version"]["files"][0]["hash"]
  if hash != expected_hash:
    sys.exit("Error: hash " + hash + " != " + expected_hash)

def read_extension_manifest(path):
  return json.loads(zipfile.ZipFile(path, 'r').read('manifest.json'))

def main(argv):
  allowed_addons_path = argv[0]
  noscript_path = argv[1]
  https_everywhere_path = argv[2]

  addons = None
  with open(allowed_addons_path, 'r') as file:
    addons = json.loads(file.read())

  noscript_hash = None
  with open(noscript_path, 'rb') as file:
    noscript_hash = "sha256:" + hashlib.sha256(file.read()).hexdigest()

  noscript_version = read_extension_manifest(noscript_path)["version"]
  https_everywhere_version = read_extension_manifest(https_everywhere_path)["version"]

  verify_extension_hash(addons, '{73a6fe31-595d-460b-a920-fcc0f8843232}', noscript_hash)
  verify_extension_version(addons, '{73a6fe31-595d-460b-a920-fcc0f8843232}', noscript_version)
  verify_extension_version(addons, 'https-everywhere-eff@eff.org', https_everywhere_version)

if __name__ == "__main__":
   main(sys.argv[1:])
