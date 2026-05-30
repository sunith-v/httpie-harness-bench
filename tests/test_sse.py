from unittest.mock import Mock

from httpie.output.sse import ServerSentEvent, iter_sse_events

from .utils import COLOR, MockEnvironment, http, strip_colors


def parse(chunks):
    return list(iter_sse_events(chunks))


def test_sse_parser_dispatches_spec_fields_incrementally():
    events = parse([
        b'\xef\xbb\xbf: comment\r\n',
        b'event: add\r',
        b'id: 1\nretry: 1500\n',
        b'data: YHOO\ndata: +2\ndata: 10\n\n',
    ])

    assert events == [
        ServerSentEvent(
            event='add',
            id='1',
            retry=1500,
            data='YHOO\n+2\n10',
        )
    ]


def test_sse_parser_handles_empty_data_and_id_reset():
    events = parse([
        b'id: 1\n',
        b'data\n\n',
        b'id\n',
        b'data:\n\n',
    ])

    assert events == [
        ServerSentEvent(event='message', id='1', retry=None, data=''),
        ServerSentEvent(event='message', id='', retry=None, data=''),
    ]


def test_sse_parser_ignores_invalid_fields_and_partial_eof_event():
    events = parse([
        b'id: good\n',
        b'id: bad\0id\n',
        b'retry: nope\n',
        b'unknown: ignored\n',
        b'data: dispatched\n\n',
        b'data: partial',
    ])

    assert events == [
        ServerSentEvent(
            event='message',
            id='good',
            retry=None,
            data='dispatched',
        )
    ]


def test_sse_parser_decodes_multibyte_utf8_across_chunks():
    events = parse([
        'data: caf'.encode(),
        'e\u0301'.encode()[:1],
        'e\u0301'.encode()[1:],
        b'\n\n',
    ])

    assert events == [
        ServerSentEvent(event='message', id='', retry=None, data='cafe\u0301')
    ]


def test_stream_sse_sets_accept_header(http_server):
    r = http('--stream-sse', '--headers', http_server + '/headers')

    assert 'Accept: text/event-stream' in r


def test_stream_sse_respects_explicit_accept_header(http_server):
    r = http(
        '--stream-sse',
        '--headers',
        http_server + '/headers',
        'Accept:application/json',
    )

    assert 'Accept: application/json' in r
    assert 'Accept: text/event-stream' not in r


def test_stream_sse_renders_labeled_event_blocks_with_json_formatting(http_server):
    env = MockEnvironment(colors=256)
    r = http('--stream-sse', http_server + '/sse', env=env)

    assert COLOR in r
    plain = strip_colors(r)
    assert 'event: add' in plain
    assert 'id: 1' in plain
    assert 'retry: 1500' in plain
    assert 'data:\n{\n    "a": 1,\n    "b": 2\n}' in plain
    assert 'event: message' in plain
    assert 'data:\nfirst line\nsecond line' in plain
    assert 'keep-alive' not in plain


def test_stream_sse_writes_each_event_as_it_arrives(http_server):
    env = MockEnvironment()
    env.stdout.write = Mock()

    http('--stream-sse', '--body', http_server + '/sse', env=env)

    event_writes = [
        call_arg
        for call_arg in env.stdout.write.call_args_list
        if 'event:' in call_arg[0][0]
    ]
    assert len(event_writes) == 2


def test_stream_sse_falls_back_for_non_event_stream(http_server):
    r = http(
        '--stream-sse',
        '--body',
        http_server + '/drip',
        'Accept:text/plain',
    )

    assert r.count('test') == 3
    assert 'event:' not in r
