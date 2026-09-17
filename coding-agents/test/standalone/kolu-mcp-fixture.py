"""Offline stand-in for kolu mcp, used only by the Claude discovery test."""
import json
import sys

assert sys.argv[1:] == ['mcp'], sys.argv
for line in sys.stdin:
    request = json.loads(line)
    if 'id' not in request:
        continue
    if request['method'] == 'initialize':
        result = {
            'protocolVersion': request['params']['protocolVersion'],
            'capabilities': {'tools': {}},
            'serverInfo': {'name': 'kolu-test', 'version': '1.0.0'},
        }
    elif request['method'] == 'tools/list':
        result = {'tools': []}
    else:
        result = {}
    print(json.dumps({'jsonrpc': '2.0', 'id': request['id'], 'result': result}), flush=True)
