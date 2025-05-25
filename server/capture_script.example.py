#!/usr/bin/env python3
"""
Wi-Fi CSI 데이터 캡처 스크립트 예제

이 스크립트는 라즈베리 파이에서 실행되어 Wi-Fi CSI 데이터를 캡처하는 역할을 합니다.
실제 구현은 다른 팀원이 담당하며, 이 파일은 예시로 제공됩니다.
"""

import sys
import time
import datetime
import json
import os
import signal
import argparse
from pathlib import Path

# 캡처 중지 플래그
stop_capture = False

def signal_handler(sig, frame):
    """Ctrl+C 시그널 처리 함수"""
    global stop_capture
    print("\n캡처 프로세스 중지 요청을 받았습니다...")
    stop_capture = True

def setup_capture_device():
    """Wi-Fi 캡처 장치 설정"""
    print("Wi-Fi 장치 설정 중...")
    # 여기에 실제 Wi-Fi 장치 설정 코드가 들어갑니다
    time.sleep(1)
    return True

def start_capture(class_id, session_id, output_dir="./captures"):
    """CSI 데이터 캡처 시작"""
    global stop_capture
    
    # 출력 디렉토리 생성
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    capture_filename = f"{output_dir}/csi_capture_{class_id}_{session_id}_{timestamp}.dat"
    
    print(f"캡처 시작: 클래스 ID {class_id}, 세션 ID {session_id}")
    print(f"캡처 파일: {capture_filename}")
    
    # 캡처 시작 시간 기록
    start_time = time.time()
    
    try:
        with open(capture_filename, 'w') as f:
            f.write(f"# CSI Capture - Class: {class_id}, Session: {session_id}\n")
            f.write(f"# Start Time: {datetime.datetime.now().isoformat()}\n")
            
            # 캡처 메타데이터 저장
            metadata = {
                "class_id": class_id,
                "session_id": session_id,
                "start_time": datetime.datetime.now().isoformat()
            }
            
            # 메타데이터 파일 생성
            metadata_file = f"{output_dir}/metadata_{class_id}_{session_id}_{timestamp}.json"
            with open(metadata_file, 'w') as mf:
                json.dump(metadata, mf, indent=2)
            
            # 캡처 루프
            packet_count = 0
            while not stop_capture:
                # 여기에 실제 CSI 데이터 캡처 코드가 들어갑니다
                # 예시: CSI 데이터 패킷 생성
                packet = {
                    "timestamp": time.time(),
                    "packet_id": packet_count,
                    "rssi": -45 - (packet_count % 10),  # 예시 값
                    "csi_data": [i for i in range(56)]  # 예시 CSI 값
                }
                
                # 데이터 기록
                f.write(f"{json.dumps(packet)}\n")
                f.flush()
                
                # 상태 출력
                if packet_count % 100 == 0:
                    elapsed = time.time() - start_time
                    print(f"캡처 진행 중: {packet_count} 패킷, {elapsed:.2f}초 경과")
                
                packet_count += 1
                time.sleep(0.1)  # 100ms 간격 (실제 구현에서는 제거)
            
            # 캡처 종료 시간 기록
            end_time = time.time()
            elapsed = end_time - start_time
            
            # 종료 정보 기록
            f.write(f"# End Time: {datetime.datetime.now().isoformat()}\n")
            f.write(f"# Total Duration: {elapsed:.2f} seconds\n")
            f.write(f"# Total Packets: {packet_count}\n")
            
            print(f"캡처 완료: {packet_count} 패킷, {elapsed:.2f}초 소요")
            
            # 메타데이터 업데이트
            metadata["end_time"] = datetime.datetime.now().isoformat()
            metadata["duration_seconds"] = elapsed
            metadata["total_packets"] = packet_count
            
            # 업데이트된 메타데이터 저장
            with open(metadata_file, 'w') as mf:
                json.dump(metadata, mf, indent=2)
                
    except Exception as e:
        print(f"캡처 오류: {e}")
        return False
    
    return True

def main():
    """메인 함수"""
    parser = argparse.ArgumentParser(description='Wi-Fi CSI 데이터 캡처 스크립트')
    parser.add_argument('class_id', help='캡처할 클래스 ID')
    parser.add_argument('session_id', help='캡처할 세션 ID')
    parser.add_argument('--output', '-o', default='./captures', help='캡처 데이터 저장 경로')
    
    args = parser.parse_args()
    
    # Ctrl+C 시그널 핸들러 등록
    signal.signal(signal.SIGINT, signal_handler)
    
    # 캡처 장치 설정
    if not setup_capture_device():
        print("캡처 장치 설정에 실패했습니다.")
        return 1
    
    # 캡처 시작
    result = start_capture(args.class_id, args.session_id, args.output)
    
    return 0 if result else 1

if __name__ == "__main__":
    sys.exit(main()) 