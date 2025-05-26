import os
import numpy as np
import cv2
import matplotlib.pyplot as plt
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dense, Dropout, InputLayer
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.utils import to_categorical
from sklearn.model_selection import train_test_split

image_folder = r"C:\image"  

categories = ['sitdown', 'empty']
images = []
labels = []

# 이미지 로딩 및 라벨링
for category in categories:
    category_path = os.path.join(image_folder)  # 카테고리별 폴더 경로
    if os.path.exists(category_path):
        for i in range(1, 1501):  # 각 카테고리에서 1000개의 이미지
            img_filename = f"{category}{i}.png"  
            img_path = os.path.join(category_path, img_filename)
            
            img = cv2.imread(img_path)
            if img is not None:  
                img = cv2.resize(img, (224, 224))  
                images.append(img)
                labels.append(categories.index(category))  

images = np.array(images)
labels = np.array(labels)

print(f"총 이미지 수: {len(images)}")
print(f"총 레이블 수: {len(labels)}")

# 이미지 정규화 및 라벨 원-핫 인코딩
if len(images) > 0:
    images = images / 255.0  
    labels = to_categorical(labels, num_classes=2)  # 클래스 수를 맞추기 위해 2로 설정

    # 80% 학습, 20% 테스트 분리
    X_train, X_test, y_train, y_test = train_test_split(images, labels, test_size=0.2, random_state=42)

    ##################################
    ########## CNN 모델 설계 ##########
    ##################################

    model = Sequential()

    model.add(Conv2D(32, (3, 3), activation='relu', input_shape=(224, 224, 3)))
    model.add(MaxPooling2D(pool_size=(2, 2)))

    model.add(Conv2D(64, (3, 3), activation='relu'))
    model.add(MaxPooling2D(pool_size=(2, 2)))

    model.add(Conv2D(128, (3, 3), activation='relu'))
    model.add(MaxPooling2D(pool_size=(2, 2)))

    model.add(Conv2D(256, (3, 3), activation='relu'))
    model.add(MaxPooling2D(pool_size=(2, 2)))

    model.add(Conv2D(256, (3, 3), activation='relu'))
    model.add(MaxPooling2D(pool_size=(2, 2)))

    model.add(Flatten())

    model.add(Dense(256, activation='relu'))
    model.add(Dropout(0.5))  
    model.add(Dense(2, activation='softmax'))  # 클래스 수 2로 변경

    ##################################
    ########## 모델 학습 #############
    ##################################

    model.compile(optimizer=Adam(learning_rate=0.001), loss='categorical_crossentropy', metrics=['accuracy'])

    history = model.fit(X_train, y_train, validation_data=(X_test, y_test), epochs=30, batch_size=32)

    ##########################################
    ######### 정확도 및 손실값 시각화 ##########
    ##########################################
        
    def plot_history(history):
        # 정확도 그래프
        plt.figure(figsize=(12, 5))
        plt.subplot(1, 2, 1)
        plt.plot(history.history['accuracy'], label='Train Accuracy')
        plt.plot(history.history['val_accuracy'], label='Validation Accuracy')
        plt.title('Model Accuracy')
        plt.xlabel('Epochs')
        plt.ylabel('Accuracy')
        plt.legend()

        # 손실 그래프
        plt.subplot(1, 2, 2)
        plt.plot(history.history['loss'], label='Train Loss')
        plt.plot(history.history['val_loss'], label='Validation Loss')
        plt.title('Model Loss')
        plt.xlabel('Epochs')
        plt.ylabel('Loss')
        plt.legend()

        plt.tight_layout()
        plt.show()

    plot_history(history)

    ###########################
    ########## 최종 결과 ##########
    ###########################
    
    test_loss, test_acc = model.evaluate(X_test, y_test)
    print(f'Test accuracy: {test_acc}')
    print(f'Test loss: {test_loss}')

else:
    print("데이터가 충분하지 않아서 학습을 진행할 수 없습니다.")

# 모델 저장
model.save(r"C:\model\csi_cnn_model.keras")  # TensorFlow 2.x 버전 호환
