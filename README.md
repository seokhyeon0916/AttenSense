# 온라인 수업 출결 관리 시스템: AttenSense📶

### 프로젝트 참여 인원🧑‍🤝‍🧑

- 운석현(팀장)
- 이경민
- 박준성

### 개발 담당🏁

- Raspberry Pi SW개발: CSI 캡처를 위한 F/W, CSI 캡처 SW 및 서버 전송 SW개발
- CNN 모델 SW 개발
- 모델 입력을 위한 DATA 전처리 및 이미지화 SW 개발

### 프로젝트 설명

- Wi-Fi의 CSI를 활용한 라즈베리파이 HAR시스템 기반 온라인 수업 출결 시스템 개발
- 무선 신호 AP장치에서 휴대폰으로 전송되는 무선 신호의 CSI(Chaennel State Information)를 활용
- CSI의 Payload를 추출하여 불필요한 부반송파 부분을 제거하는 전처리 과정을 거친 후 Heatmap형태로 변환
- 기존 학습된 CNN모델에 입력된 후 학생의 상태를 sitdown, empty로 분류하여 교수자에게 알림

### Tech Stacks🔨

- #### Front-end</br>
  <img src="https://img.shields.io/badge/FLutter-02569B?style=for-the-badge&logo=Flutter&logoColor=FFFFFF"/>
- #### Back-end</br>
   <img src="https://img.shields.io/badge/node.js-339933?style=for-the-badge&logo=Node.js&logoColor=white">
   <img src="https://img.shields.io/badge/python-3776AB?style=for-the-badge&logo=python&logoColor=white">
   <img src="https://img.shields.io/badge/Firebase-DD2C00?style=for-the-badge&logo=Firebase&logoColor=FFFFFF"/>
- #### Server</br>
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=Docker&logoColor=FFFFFF"/>
  <img src="https://img.shields.io/badge/GoogleCloud-4285F4?style=for-the-badge&logo=GoogleCloud&logoColor=FFFFFF"/>
- #### H/W
  <img src="https://img.shields.io/badge/RaspberryPi-A22846?style=for-the-badge&logo=RaspberryPi&logoColor=FFFFFF">
  <img src="https://img.shields.io/badge/linux-FCC624?style=for-the-badge&logo=linux&logoColor=black">
  <img src="https://img.shields.io/badge/OpenWrt-00B5E2?style=for-the-badge&logo=OpenWrt&logoColor=black">

### 프로젝트 아키텍쳐🖼️

<img src="https://github.com/user-attachments/assets/02834672-3dfc-4c6e-b5d4-c4ee9f880366">
