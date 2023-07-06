import math
import numpy as np
from scipy import signal
from scipy.io import wavfile
from matplotlib import pyplot as plt

SAMPLE_RATE = 48000
HEADER = [x - ord('0') for x in b'01010101']


def ask_modulate(data: np.ndarray, rate: int, fre: int, filename: str, sample_rate=SAMPLE_RATE):
    """
    data: 一个一维数组，每一个元素取值为0/1.代表待调制的比特
    rate: 通信速率(bps)
    fre:载波频率(Hz)
    filename: 输出的文件名(例:"output.wav")

    要求:将data按照rate的速率，调制在频率为fre的正弦载波上。以48000的采样率输出到filename上
    """
    size = len(data)
    span = size / rate  # 总时长
    sample_count = int(span * sample_rate)
    samples_per_bit = sample_rate / rate
    samples_per_circle = sample_rate / fre
    omega = 2 * np.pi / samples_per_circle

    float_data = [data[int(i / samples_per_bit)] * math.sin(omega * i) for i in range(sample_count)]

    float_data = np.array(float_data)

    if filename is not None:
        wavfile.write(filename, sample_rate, float_data)
    return float_data


def ask_demodulate(rate: int, fre: int, filename: str, bias=500) -> np.ndarray:
    """
    rate: 通信速率(bps)
    fre:载波频率(Hz)
    filename: 输出的文件名(例:"output.wav")

    要求:将filename的文件读入，用fre-500hz~fre+500hz的带通滤波器过滤信号。然后用包络解调法解调，产生的1维数组作为函数返回值
    """
    content = filename if isinstance(filename, tuple) else wavfile.read(filename)
    sample_rate, raw_signal = content

    order = 6  # 滤波器的阶数
    wn1 = 2 * max(float(fre - bias), .1) / sample_rate
    wn2 = 2 * (fre + bias) / sample_rate
    b, a = signal.butter(order, [wn1, wn2], 'bandpass')
    bandpass_out = signal.filtfilt(b, a, raw_signal)  # 带通滤波

    sample_count = len(raw_signal)

    analytic_signal = signal.hilbert(bandpass_out)
    amplitude_envelope = np.abs(analytic_signal)

    samples_per_bit = sample_rate // rate
    header_signal = np.array([[x for _ in range(samples_per_bit)] for x in HEADER]).flat
    corr_values = np.correlate(amplitude_envelope, header_signal, "full")
    lagged_count = corr_values.argmax() - len(header_signal) + 1
    aligned_envelope = amplitude_envelope[lagged_count:]

    bit_count = (sample_count - lagged_count) // samples_per_bit
    detection_bpsk = np.zeros(bit_count, dtype=np.int32)
    threshold = samples_per_bit * .5
    for i in range(bit_count):
        offset = i * samples_per_bit
        acc = 0
        for j in range(samples_per_bit):
            acc += aligned_envelope[offset + j]
        detection_bpsk[i] = acc > threshold

    return detection_bpsk


if __name__ == '__main__':
    # 定义加性高斯白噪声
    def awgn(y, snr):
        snr = 10 ** (snr / 10.0)
        xpower = np.sum(y ** 2) / len(y)
        npower = xpower / snr
        return np.random.randn(len(y)) * np.sqrt(npower) + y


    filename = './output.wav'
    fre = 1000
    rate = 50
    payload = np.random.randint(2, size=10)
    data = np.concatenate((HEADER, payload))

    float_data = ask_modulate(data, rate, fre, None)

    lags = np.random.rand(int(np.random.random() * len(HEADER) + SAMPLE_RATE / rate))
    # 加AWGN噪声
    with_noise = np.concatenate((
        lags,
        awgn(float_data, 5),
        lags,
    ))
    parsed_data = ask_demodulate(rate, fre, (SAMPLE_RATE, with_noise))

    # all_equal = (data == parsed_data).all()
    # print(all_equal)
    plt.plot(data, drawstyle='steps-pre')
    plt.show()
    plt.plot(float_data)
    plt.show()
    plt.plot(with_noise)
    plt.show()
    plt.plot(parsed_data, drawstyle='steps-pre')
    plt.show()
