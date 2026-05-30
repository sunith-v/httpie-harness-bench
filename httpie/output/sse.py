import codecs
from typing import Iterable, Iterator, NamedTuple, Optional

from ..encoding import UTF8


class ServerSentEvent(NamedTuple):
    event: str
    data: str
    id: str
    retry: Optional[int] = None


def iter_sse_events(chunks: Iterable[bytes]) -> Iterator[ServerSentEvent]:
    """Parse a UTF-8 server-sent event stream into dispatched events."""
    data_lines = []
    event_type = ''
    last_event_id = ''
    retry = None

    for line in iter_sse_lines(chunks):
        if not line:
            if data_lines:
                yield ServerSentEvent(
                    event=event_type or 'message',
                    data='\n'.join(data_lines),
                    id=last_event_id,
                    retry=retry,
                )
            data_lines = []
            event_type = ''
            retry = None
            continue

        if line.startswith(':'):
            continue

        if ':' in line:
            field, value = line.split(':', 1)
            if value.startswith(' '):
                value = value[1:]
        else:
            field, value = line, ''

        if field == 'event':
            event_type = value
        elif field == 'data':
            data_lines.append(value)
        elif field == 'id':
            if '\0' not in value:
                last_event_id = value
        elif field == 'retry':
            if value.isascii() and value.isdigit():
                retry = int(value)


def iter_sse_lines(chunks: Iterable[bytes]) -> Iterator[str]:
    """Yield decoded SSE lines, handling CRLF, LF, and CR across chunks."""
    decoder = codecs.getincrementaldecoder(UTF8)('replace')
    pending = ''
    bom_checked = False

    for chunk in chunks:
        text = decoder.decode(chunk)
        if not bom_checked and text:
            if text.startswith('\ufeff'):
                text = text[1:]
            bom_checked = True

        pending += text
        start = 0
        index = 0
        while index < len(pending):
            char = pending[index]
            if char == '\r':
                if index + 1 == len(pending):
                    break
                yield pending[start:index]
                index += 2 if pending[index + 1] == '\n' else 1
                start = index
                continue
            if char == '\n':
                yield pending[start:index]
                index += 1
                start = index
                continue
            index += 1
        pending = pending[start:]

    tail = decoder.decode(b'', final=True)
    if tail:
        pending += tail

    start = 0
    index = 0
    while index < len(pending):
        char = pending[index]
        if char == '\r':
            yield pending[start:index]
            index += 2 if index + 1 < len(pending) and pending[index + 1] == '\n' else 1
            start = index
            continue
        if char == '\n':
            yield pending[start:index]
            index += 1
            start = index
            continue
        index += 1
