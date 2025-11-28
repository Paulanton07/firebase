
// recorder.worklet.js
class RecorderProcessor extends AudioWorkletProcessor {
  constructor(options) {
    super();

    this._bufferSize = options.processorOptions.bufferSize;
    this._channelCount = options.processorOptions.channelCount;
    this._sampleRate = options.processorOptions.sampleRate;

    this._initBuffer();

    this.port.onmessage = (e) => {
      if (e.data.command === 'getBuffer') {
        this.port.postMessage(this._buffer);
      }
    };
  }

  _initBuffer() {
    this._buffer = [];
    for (let i = 0; i < this._channelCount; i++) {
      this._buffer.push(new Float32Array(this._bufferSize));
    }
  }

  process(inputs, outputs, parameters) {
    const input = inputs[0];

    if (input.length > 0) {
      for (let i = 0; i < this._channelCount; i++) {
        this._buffer[i] = input[i];
      }

      this.port.postMessage(this._buffer);
    }

    return true;
  }
}

registerProcessor('recorder-processor', RecorderProcessor);
