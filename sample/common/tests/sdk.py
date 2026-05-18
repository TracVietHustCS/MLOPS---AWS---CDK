import boto3
import json
import io

smr = boto3.client('sagemaker-runtime', region_name="ap-northeast-1")

class LineIterator:
    def __init__(self, stream):
        self.byte_iterator = iter(stream)
        self.buffer = io.BytesIO()
        self.read_pos = 0

    def __iter__(self):
        return self

    def __next__(self):
        while True:
            self.buffer.seek(self.read_pos)
            line = self.buffer.readline()
            if line and line[-1] == ord('\n'):
                self.read_pos += len(line)
                return line[:-1]
            try:
                chunk = next(self.byte_iterator)
            except StopIteration:
                if self.read_pos < self.buffer.getbuffer().nbytes:
                    continue
                raise
            if 'PayloadPart' not in chunk:
                print('Unknown event type:' + chunk)
                continue
            self.buffer.seek(0, io.SEEK_END)
            self.buffer.write(chunk['PayloadPart']['Bytes'])


endpoint_name = "acb-dev-qwen3-30b-a3b-instruct-2507-fp8"

body = {
    "messages": [
        {"role": "user", "content": "Giới thiệu về dịch vụ EC2 của AWS"}
    ],
    "max_tokens": 2048,
    "temperature": 0.7,
    "stream": True,
}

resp = smr.invoke_endpoint_with_response_stream(
    EndpointName=endpoint_name,
    Body=json.dumps(body),
    ContentType="application/json"
)
event_stream = resp['Body']


for line in LineIterator(event_stream):
    resp = json.loads(line)
    print(resp["choices"][0]["delta"]["content"], end="")
