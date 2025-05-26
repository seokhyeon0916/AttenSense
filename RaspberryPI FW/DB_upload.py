import scapy.all as scapy
import firebase_admin
from firebase_admin import credentials, db
import base64
import os

# Firebase 인증 정보 설정
firebase_key_path = "/home/pi/firebase_key.json"

# Firebase 초기화
if not firebase_admin._apps:
    cred = credentials.Certificate(firebase_key_path)
    firebase_admin.initialize_app(cred, {
        'databaseURL': 'https://csi-online-attendance-system-default-rtdb.asia-southeast1.firebasedatabase.app/'
    })

def extract_payloads(pcap_file):
    """pcap 파일에서 payload 추출"""
    packets = scapy.rdpcap(pcap_file)
    payloads = []

    for packet in packets:
        if packet.haslayer(scapy.Raw):
            raw_data = packet[scapy.Raw].load
            encoded_payload = base64.b64encode(raw_data).decode()
            payloads.append(encoded_payload)

    return payloads

def send_to_firebase(filename, payloads):
    """payload를 Firebase에 업로드"""
    filename_without_ext = os.path.splitext(filename)[0]
    ref = db.reference(f"/pcap_payloads/{filename_without_ext}")

    for i, payload in enumerate(payloads):
        ref.child(f"packet_{i}").set({"payload": payload})

    print(f"✅ {filename}의 {len(payloads)}개 payload가 Firebase로 전송됨")

def process_pcap_files(directory):
    """capston 폴더 내의 pcap 파일을 자동 처리"""
    for filename in os.listdir(directory):
        if filename.endswith(".pcap"):
            pcap_path = os.path.join(directory, filename)
            print(f"처리중:{filename}")
            try:
                payloads = extract_payloads(pcap_path)

                if payloads:
                    send_to_firebase(filename, payloads)
                    os.remove(pcap_path)  # 업로드 후 삭제
                    print(f" {filename} 삭제 완료\n")
                else:
                    print(f"⚠️ {filename}: 추출된 payload 없음\n")

            except Exception as e:
                print(f"❌ {filename} 처리 중 오류 발생: {e}\n")

# 실행
if __name__ == "__main__":
    capston_dir = "/home/pi/nexmon/capstone_data/"
    if os.path.exists(capston_dir):
        process_pcap_files(capston_dir)
    else:
        print(f"❌ 디렉토리 없음: {capston_dir}")
