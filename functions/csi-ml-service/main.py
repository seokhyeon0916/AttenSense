import os
import json
import logging
import traceback
import numpy as np
from datetime import datetime
from flask import Flask, request, jsonify
from google.cloud import storage, firestore

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 환경 설정
PROJECT_ID = os.environ.get('GOOGLE_CLOUD_PROJECT', 'csi-online-attendance-system')
BUCKET_NAME = os.environ.get('CSI_DATA_BUCKET', f'{PROJECT_ID}-csi-data')

# Storage 클라이언트 초기화
storage_client = storage.Client()
db = firestore.Client()

# 플라스크 앱 초기화 (Cloud Functions와 호환)
app = Flask(__name__)

# CSI 활동 감지 모델 클래스
class CSIActivityClassifier:
    """
    CSI 데이터를 기반으로 활동/비활동 여부를 판별하는 모델
    
    실제 프로젝트에서는 이 부분에 학습된 ML 모델을 로드하여 사용
    현재는 간단한 임계값 기반 판별 로직으로 구현
    """
    
    def __init__(self):
        self.threshold = 3.0  # 활동/비활동 판별 임계값
        logger.info("CSI 활동 감지 모델 초기화")
    
    def predict(self, csi_data):
        """CSI 데이터로부터 활동 여부 예측"""
        try:
            # 데이터 검증
            if not isinstance(csi_data, (list, np.ndarray)):
                logger.error(f"유효하지 않은 CSI 데이터 형식: {type(csi_data)}")
                return 0.0
            
            # 간단한 변동성 계산 (표준편차)
            # 실제 구현에서는 보다 복잡한 알고리즘 적용
            csi_array = np.array(csi_data)
            if len(csi_array) < 2:
                logger.warning("CSI 데이터 포인트가 부족함")
                return 0.0
                
            # 변동성 계산 (시간에 따른 진폭 변화의 표준편차)
            std_dev = np.std(csi_array)
            
            # 변동성이 임계값을 넘으면 활동 중으로 판단
            activity_score = std_dev / self.threshold
            
            logger.info(f"활동 점수: {activity_score:.4f} (std_dev={std_dev:.4f}, threshold={self.threshold})")
            return float(activity_score)
            
        except Exception as e:
            logger.error(f"예측 중 오류 발생: {e}")
            traceback.print_exc()
            return 0.0
    
    def is_active(self, csi_data, threshold_multiplier=1.0):
        """활동 여부 판별 (True/False)"""
        score = self.predict(csi_data)
        adjusted_threshold = 1.0 * threshold_multiplier
        return score > adjusted_threshold, score

# 모델 인스턴스 생성
model = CSIActivityClassifier()

@app.route('/predict', methods=['POST'])
def predict():
    """CSI 데이터로부터 활동 여부 예측 API"""
    try:
        # 요청 데이터 파싱
        data = request.get_json(force=True)
        
        # 필수 파라미터 검증
        if 'csi_data' not in data:
            return jsonify({
                'error': 'Missing required parameter: csi_data',
                'timestamp': datetime.now().isoformat()
            }), 400
            
        csi_data = data['csi_data']
        session_id = data.get('session_id')
        student_id = data.get('student_id')
        timestamp = data.get('timestamp', datetime.now().isoformat())
        
        # 활동 여부 예측
        is_active, confidence = model.is_active(csi_data)
        
        # 결과 생성
        result = {
            'is_active': bool(is_active),
            'confidence': float(confidence),
            'timestamp': timestamp
        }
        
        # 세션 및 학생 ID가 제공된 경우 Firestore에 결과 저장
        if session_id and student_id:
            try:
                # Firestore 컬렉션 참조
                activity_ref = db.collection('activity_logs').document()
                
                # 활동 로그 저장
                activity_ref.set({
                    'session_id': session_id,
                    'student_id': student_id,
                    'is_active': bool(is_active),
                    'confidence': float(confidence),
                    'timestamp': firestore.SERVER_TIMESTAMP,
                    'recorded_at': timestamp
                })
                
                logger.info(f"활동 로그 저장됨: {session_id}/{student_id}")
                result['log_id'] = activity_ref.id
                
            except Exception as db_error:
                logger.error(f"Firestore 저장 오류: {db_error}")
                result['db_error'] = str(db_error)
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"API 요청 처리 중 오류: {e}")
        traceback.print_exc()
        return jsonify({
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/health', methods=['GET'])
def health_check():
    """서비스 상태 확인 API"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'csi-ml-service'
    })

# Cloud Functions 진입점
def csi_ml_service(request):
    """Cloud Functions 핸들러"""
    return app(request)

# 로컬 테스트를 위한 서버 실행
if __name__ == "__main__":
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=True) 