"""
AgriSmartAI - MobileNetV2 Training Script
OBJECTIVE 2: Train MobileNetV2 to identify 3 rice diseases with at least 85% accuracy.
OBJECTIVE 1: Dataset expected at dataset/ with 500 images each from 10 farms.

Dataset structure required:
  dataset/
    bacterial_leaf_blight/   <- 500 images from >= 10 farms in New Bataan
    rice_blast/              <- 500 images from >= 10 farms in New Bataan
    tungro/                  <- 500 images from >= 10 farms in New Bataan
    healthy/                 <- optional healthy rice images

Output:
  models/rice_disease_model.h5      (Keras format)
  models/rice_disease_model.tflite  (for Flutter mobile app)
  models/labels.txt
  models/training_history.png
"""

import os
import numpy as np
import tensorflow as tf
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import GlobalAveragePooling2D, Dense, Dropout, BatchNormalization
from tensorflow.keras.models import Model
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import ModelCheckpoint, EarlyStopping, ReduceLROnPlateau
from sklearn.metrics import classification_report, confusion_matrix
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns

# ============================================================
# Configuration
# ============================================================
DATASET_DIR = 'dataset'
MODEL_DIR = 'models'
IMG_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 30
LEARNING_RATE = 0.0001
VALIDATION_SPLIT = 0.2
TARGET_ACCURACY = 0.85

os.makedirs(MODEL_DIR, exist_ok=True)

# ============================================================
# Data augmentation and loading
# ============================================================
train_datagen = ImageDataGenerator(
    rescale=1.0 / 255,
    rotation_range=20,
    width_shift_range=0.15,
    height_shift_range=0.15,
    shear_range=0.1,
    zoom_range=0.15,
    horizontal_flip=True,
    brightness_range=[0.8, 1.2],
    validation_split=VALIDATION_SPLIT,
)

val_datagen = ImageDataGenerator(
    rescale=1.0 / 255,
    validation_split=VALIDATION_SPLIT,
)

print('Loading training data...')
train_gen = train_datagen.flow_from_directory(
    DATASET_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    subset='training',
    shuffle=True,
)

val_gen = val_datagen.flow_from_directory(
    DATASET_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    subset='validation',
    shuffle=False,
)

CLASS_NAMES = list(train_gen.class_indices.keys())
NUM_CLASSES = len(CLASS_NAMES)
print(f'Classes detected: {CLASS_NAMES}')
print(f'Training samples: {train_gen.samples}')
print(f'Validation samples: {val_gen.samples}')

# Validate minimum dataset size (OBJECTIVE 1)
for cls in CLASS_NAMES:
    cls_path = os.path.join(DATASET_DIR, cls)
    img_count = len([f for f in os.listdir(cls_path)
                     if f.lower().endswith(('.jpg', '.jpeg', '.png'))])
    print(f'  {cls}: {img_count} images', end='')
    if img_count < 500:
        print(f' *** WARNING: Less than 500 images (need 500 from 10+ farms)')
    else:
        print(f' ✓')

# ============================================================
# Build MobileNetV2 model (OBJECTIVE 2)
# ============================================================
print('\nBuilding MobileNetV2 model...')
base_model = MobileNetV2(
    input_shape=(*IMG_SIZE, 3),
    include_top=False,
    weights='imagenet',
)

# Freeze base initially for transfer learning
base_model.trainable = False

x = base_model.output
x = GlobalAveragePooling2D()(x)
x = BatchNormalization()(x)
x = Dense(256, activation='relu')(x)
x = Dropout(0.5)(x)
x = BatchNormalization()(x)
x = Dense(128, activation='relu')(x)
x = Dropout(0.3)(x)
output = Dense(NUM_CLASSES, activation='softmax')(x)

model = Model(inputs=base_model.input, outputs=output)

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=LEARNING_RATE),
    loss='categorical_crossentropy',
    metrics=['accuracy'],
)

model.summary()

# ============================================================
# Callbacks
# ============================================================
callbacks = [
    ModelCheckpoint(
        filepath=os.path.join(MODEL_DIR, 'best_model.h5'),
        monitor='val_accuracy',
        save_best_only=True,
        verbose=1,
    ),
    EarlyStopping(
        monitor='val_accuracy',
        patience=8,
        restore_best_weights=True,
        verbose=1,
    ),
    ReduceLROnPlateau(
        monitor='val_loss',
        factor=0.3,
        patience=4,
        min_lr=1e-7,
        verbose=1,
    ),
]

# ============================================================
# Phase 1: Train with frozen base
# ============================================================
print('\n=== Phase 1: Training classifier head (base frozen) ===')
history1 = model.fit(
    train_gen,
    validation_data=val_gen,
    epochs=10,
    callbacks=callbacks,
)

# ============================================================
# Phase 2: Fine-tune top layers of MobileNetV2
# ============================================================
print('\n=== Phase 2: Fine-tuning MobileNetV2 top layers ===')
base_model.trainable = True
# Unfreeze top 30 layers
for layer in base_model.layers[:-30]:
    layer.trainable = False

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=LEARNING_RATE / 10),
    loss='categorical_crossentropy',
    metrics=['accuracy'],
)

history2 = model.fit(
    train_gen,
    validation_data=val_gen,
    epochs=EPOCHS,
    callbacks=callbacks,
    initial_epoch=len(history1.epoch),
)

# ============================================================
# Evaluate (OBJECTIVE 2: target >= 85% accuracy)
# ============================================================
print('\n=== Evaluating model ===')
val_loss, val_accuracy = model.evaluate(val_gen, verbose=1)
print(f'\nFinal Validation Accuracy: {val_accuracy * 100:.2f}%')
print(f'Target: {TARGET_ACCURACY * 100:.0f}%')
if val_accuracy >= TARGET_ACCURACY:
    print('✓ OBJECTIVE 2 ACHIEVED: Model accuracy meets 85% target')
else:
    print('✗ Accuracy below target. Collect more data or tune hyperparameters.')

# Classification report
val_gen.reset()
y_pred_probs = model.predict(val_gen)
y_pred = np.argmax(y_pred_probs, axis=1)
y_true = val_gen.classes

print('\nClassification Report:')
print(classification_report(y_true, y_pred, target_names=CLASS_NAMES))

# ============================================================
# Confusion matrix plot
# ============================================================
cm = confusion_matrix(y_true, y_pred)
plt.figure(figsize=(8, 6))
sns.heatmap(cm, annot=True, fmt='d', cmap='Greens',
            xticklabels=CLASS_NAMES, yticklabels=CLASS_NAMES)
plt.title('Confusion Matrix')
plt.ylabel('True Label')
plt.xlabel('Predicted Label')
plt.tight_layout()
plt.savefig(os.path.join(MODEL_DIR, 'confusion_matrix.png'))
print('Confusion matrix saved.')

# Training history plot
all_acc = history1.history['accuracy'] + history2.history['accuracy']
all_val_acc = history1.history['val_accuracy'] + history2.history['val_accuracy']
all_loss = history1.history['loss'] + history2.history['loss']
all_val_loss = history1.history['val_loss'] + history2.history['val_loss']

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4))
ax1.plot(all_acc, label='Train Accuracy')
ax1.plot(all_val_acc, label='Val Accuracy')
ax1.axhline(y=TARGET_ACCURACY, color='r', linestyle='--', label='Target (85%)')
ax1.set_title('Model Accuracy')
ax1.set_xlabel('Epoch')
ax1.legend()

ax2.plot(all_loss, label='Train Loss')
ax2.plot(all_val_loss, label='Val Loss')
ax2.set_title('Model Loss')
ax2.set_xlabel('Epoch')
ax2.legend()

plt.tight_layout()
plt.savefig(os.path.join(MODEL_DIR, 'training_history.png'))
print('Training history plot saved.')

# ============================================================
# Save Keras model
# ============================================================
keras_path = os.path.join(MODEL_DIR, 'rice_disease_model.h5')
model.save(keras_path)
print(f'Keras model saved: {keras_path}')

# ============================================================
# Convert to TFLite (for Flutter mobile app)
# ============================================================
print('\nConverting to TFLite...')
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]  # Quantization for smaller model
tflite_model = converter.convert()

tflite_path = os.path.join(MODEL_DIR, 'rice_disease_model.tflite')
with open(tflite_path, 'wb') as f:
    f.write(tflite_model)
print(f'TFLite model saved: {tflite_path}  ({len(tflite_model) / 1024:.0f} KB)')

# Save labels.txt
labels_path = os.path.join(MODEL_DIR, 'labels.txt')
with open(labels_path, 'w') as f:
    for cls in CLASS_NAMES:
        f.write(cls + '\n')
print(f'Labels saved: {labels_path}')

print('\n=== Training Complete ===')
print(f'Copy the following files to your Flutter app:')
print(f'  {tflite_path} → frontend/farmer_mobile_app/assets/model/model.tflite')
print(f'  {labels_path} → frontend/farmer_mobile_app/assets/model/labels.txt')
