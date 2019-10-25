import datetime
import json
import re
import sys

GC_RE = re.compile(r'GC: \d:(?P<type>[^ ]+) @ (?P<before>[^\(]+).*; free (?P<after>[^\(]+)\((?P<delta>[^\)]+)\) (?P<duration>[^ ]+)')  # noqa


def numberify(s):
    s = s.replace(',', '')
    if s.endswith('K'):
        return int(s[:-1]) * 1000
    if s.endswith('M'):
        return int(s[:-1]) * 1000000
    if s.endswith('ms'):
        return int(s[:-2]) * 1000
    raise ValueError(f'cannot numberify {s}')


try:
    while True:
        line = sys.stdin.readline()
        if not line:
            break

        if line.startswith('GC:'):
            data = GC_RE.match(line).groupdict()
            sys.stderr.write(json.dumps({
                'timestamp': datetime.datetime.utcnow().isoformat() + 'Z',
                'type': data['type'].lower(),
                'before': numberify(data['before']),
                'after': numberify(data['after']),
                'delta': numberify(data['delta']),
                'duration': numberify(data['duration']),
                'latency': numberify(data['duration']),
            }))
            sys.stderr.write('\n')

        else:
            print(line.rstrip())
except KeyboardInterrupt:
    pass
