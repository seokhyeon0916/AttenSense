#!/bin/bash
# Cloud Functions 배포 스크립트

# 프로젝트 ID (배포 전 수정 필요)
PROJECT_ID="csi-online-attendance-system"

# 리전 (서울 리전)
REGION="asia-northeast3"

# CSI ML 서비스 배포
echo "CSI ML 서비스 배포 중..."
gcloud functions deploy csi-ml-service \
  --gen2 \
  --region=$REGION \
  --runtime=python310 \
  --source=./csi-ml-service \
  --entry-point=csi_ml_service \
  --trigger-http \
  --memory=512Mi \
  --min-instances=0 \
  --max-instances=10 \
  --timeout=60s \
  --allow-unauthenticated

# 배포 결과 확인
echo "배포 완료. 함수 URL 확인:"
gcloud functions describe csi-ml-service \
  --gen2 \
  --region=$REGION \
  --format="value(serviceConfig.uri)" 