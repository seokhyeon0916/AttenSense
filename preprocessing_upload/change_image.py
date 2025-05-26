import firebase_admin
from firebase_admin import credentials, db
import numpy as np
import cv2  # OpenCV로 이미지 리사이징

# Firebase 인증 및 초기화
firebase_key_path = r"C:\capston_code\firebase_key.json"
if not firebase_admin._apps:
    cred = credentials.Certificate(firebase_key_path)
    firebase_admin.initialize_app(cred, {
        'databaseURL': 'https://csi-online-attendance-system-default-rtdb.asia-southeast1.firebasedatabase.app/',
    })

def get_heatmap_from_firebase(category="empty", i=50):
    # Firebase에서 데이터 불러오기
    ref = db.reference(f'/csidata/{category}/{i}')
    snapshot = ref.get()

    # 패킷 0~19 진폭 불러오기
    db_amplitudes_list = []
    for p in range(20):  # 0~19번 패킷
        key = f'packet_{p}'
        if key in snapshot:
            amplitudes_str = snapshot[key]
            amplitudes = list(map(float, amplitudes_str.split(',')))
            db_amplitudes_list.append(amplitudes)

    # numpy array로 변환 (형태: [20][52])
    heatmap_array = np.array(db_amplitudes_list)

    # 리사이즈: (20, 52) → (224, 224)
    resized = cv2.resize(heatmap_array, (224, 224), interpolation=cv2.INTER_LINEAR)

    # 흑백 → RGB 채널 3개로 복제 → (224, 224, 3)
    rgb_image = np.stack([resized] * 3, axis=-1)

    # CNN 입력을 위해 float32 변환 및 배치 차원 추가 → (1, 224, 224, 3)
    input_tensor = np.expand_dims(rgb_image.astype(np.float32), axis=0)

    return input_tensor
