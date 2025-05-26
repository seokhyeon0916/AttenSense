import firebase_admin
from firebase_admin import credentials, db
from tensorflow.keras.models import load_model
import numpy as np
import matplotlib.pyplot as plt
import io
import cv2
import time
import requests

# 🔧 경로 직접 지정
firebase_key_path = r"C:\capston_code\firebase_key.json"
model_path = r"C:\model\csi_cnn_model.keras"


# ✅ Firebase 초기화
if not firebase_admin._apps:
    cred = credentials.Certificate(firebase_key_path)
    firebase_admin.initialize_app(cred, {
        'databaseURL': 'https://csi-online-attendance-system-default-rtdb.asia-southeast1.firebasedatabase.app/',
    })

# ✅ 모델 로드
model = load_model(model_path)
class_labels = ['empty', 'sitdown']


# 🔧 Firebase에서 데이터 가져와 heatmap 이미지로 변환
def get_heatmap_from_firebase(category, index):
    try:
        ref = db.reference(f'/csidata/{category}/{index}')
        raw_data = ref.get()

        if not raw_data:
            print("⚠️ Firebase 데이터가 비어 있음.")
            return None

        # packet_0 ~ packet_19 가져오기
        packet_data = []
        for i in range(20):
            packet_key = f'packet_{i}'
            if packet_key in raw_data:
                str_values = raw_data[packet_key].strip().split(',')
                float_values = [float(val) for val in str_values if val.strip()]
                packet_data.append(float_values)
            else:
                print(f"❌ {packet_key} 없음.")
                return None

        data_array = np.array(packet_data)

        # Heatmap 이미지 생성
        fig, ax = plt.subplots(figsize=(3, 3), dpi=75)
        ax.axis('off')
        ax.imshow(data_array, cmap='jet', aspect='auto')
        plt.tight_layout(pad=0)

        buf = io.BytesIO()
        plt.savefig(buf, format='png')
        buf.seek(0)
        img_array = np.frombuffer(buf.getvalue(), dtype=np.uint8)
        img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
        buf.close()
        plt.close(fig)

        img = cv2.resize(img, (224, 224))
        img = img / 255.0
        img = np.expand_dims(img, axis=0)
        return img

    except Exception as e:
        print(f"🔥 오류 발생: {e}")
        return None


# ✅ 예측 수행 + 프론트로 전송
def run_prediction(category, index):
    input_tensor = get_heatmap_from_firebase(category, index)
    if input_tensor is not None:
        predictions = model.predict(input_tensor)
        predicted_class = np.argmax(predictions)
        confidence = float(np.max(predictions))
        label = class_labels[predicted_class]
        print(f"📌 예측 결과: {category}/{index} → {label} (신뢰도: {confidence:.2f})")

        # Firebase에 예측 결과 저장
        try:
            pred_ref = db.reference(f'/prediction/{category}/{index}')
            pred_ref.set({
                'label': label,
                'confidence': confidence,
                'timestamp': int(time.time())
            })
            print("✅ Firebase에 예측 결과 저장 완료")
        except Exception as e:
            print(f"🚨 Firebase 저장 오류: {e}")

    else:
        print(f"⚠️ 데이터 없음: {category}/{index}")



# 🔁 Firebase 리스너
def listener(event):
    if event.data is None:
        return

    path_parts = event.path.strip("/").split("/")
    if len(path_parts) == 2:
        category, index_str = path_parts
        try:
            index = int(index_str)
            print(f"\n🔥 새 데이터 감지: category={category}, index={index}")
            run_prediction(category, index)
        except ValueError:
            print(f"❌ index 변환 실패: {index_str}")


# 📡 Firebase 리스너 등록 및 대기
ref = db.reference('/csidata')
ref.listen(listener)

print("✅ Firebase 실시간 감지 대기 중...")
while True:
    time.sleep(60)  # 리스너 유지용
