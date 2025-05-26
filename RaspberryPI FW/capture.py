import subprocess

def run_tcpdump():
    try:
        # tcpdump 명령어 실행
        command = "tcpdump -i wlan0 dst port 5500 -vv -w test.pcap -c 20"
        process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        # 출력과 에러 읽기
        stdout, stderr = process.communicate()

        # 결과 출력
        if process.returncode == 0:
            print("tcpdump 실행 성공")
            print(stdout.decode())
        else:
            print("tcpdump 실행 실패")
            print(stderr.decode())
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    run_tcpdump()
