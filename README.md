## My NeuralStyleTransfer

### WEEK 1 (1.27-2.2) - WEEK 2 (2.3-2.9)
1. study the paper, VGG-19

2. find some pre-trained model


### WEEK 3 (2.10-2.16)
#### step 0: set the environment on ubuntu

1. install the NVIDIA driver:

   https://blog.csdn.net/u014797226/article/details/79626693

2. The screen resolution becomes smaller after the driver is installed.

   https://chenzhen.online/2019/01/13/2019-01-13-%E8%A7%A3%E5%86%B3Ubuntu16.04%E5%AE%89%E8%A3%85Nvidia%E5%90%8E%EF%BC%8C%E5%88%86%E8%BE%A8%E7%8E%87%E6%97%A0%E6%B3%95%E8%B0%83%E6%95%B4%E7%9A%84%E9%97%AE%E9%A2%98/

3. install CUDA and cuNN

   https://blog.csdn.net/u014797226/article/details/80229887

4. install TensorFlow-gpu 1.0.0, Python 2.7.12, Pillow 3.4.2, scipy 0.18.1, numpy 1.11.2 on ubuntu

   pip install tensorflow-gpu==1.0.0

#### step 1: download the sourcecode and train on ubuntu

1. multi-style

   This is the muti-style version getting from the github. 

   I use it to learn how neural network transfer works.

   https://github.com/hmi88/Fast_Multi_Style_Transfer-tensorflow

   put it here:

   /Users/xiaoyuwang/Desktop/capstone/Multi_style_transfer

2. single-style

   I use this one on my project.

   https://github.com/lengstrom/fast-style-transfer

   put it here:

   /Users/xiaoyuwang/Desktop/capstone/fast-style-transfer

### WEEK 4 (2.17-2.23)
#### step 2: get the output_node_names

/Users/xiaoyuwang/Desktop/capstone/fast-style-transfer/models/rain_princess/step1_getoutputnode.py
```python
from tensorflow.python import pywrap_tensorflow
import tensorflow as tf
# way 1
ckpt = './fns.ckpt'
with tf.Session() as sess:
    saver = tf.train.import_meta_graph(ckpt + '.meta', clear_devices=True)
    graph_def = tf.get_default_graph().as_graph_def(add_shapes=True)
    node_list=[n.name for n in graph_def.node]
    for node in node_list:
        print (node)
```
#### step 3:convert ckpt model to .pb using tensorflow tools

1) copy freeze_graph.py from tensorflow dir:

   /Users/xiaoyuwang/Library/Python/2.7/lib/python/site-packages/tensorflow/python/tools/freeze_graph.py

   put it here:

   /Users/xiaoyuwang/Desktop/capstone

2) modify it according to:

   (1) modify freeze_graph.py: import meta_graph(from tensorflow.python.framework import meta_graph)

   (2) modify line 91-97: input_graph_def = meta_graph.read_meta_graph_file(input_graph).graph_def

3) once we get the output_node_names in step 2, and prepare the freeze_graph.py,

   execute the shell, step2_ckpt2pb.sh
   ```
   python /Users/xiaoyuwang/Desktop/capstone/freeze_graph.py \
   --input_graph=./fns.ckpt.meta \
   --input_checkpoint=./fns.ckpt \
   --output_graph=rain_princess.pb \
   --output_node_names=add_37 \
   --input_binary=True
   ```

### WEEK 5(2.24-3.1) (dosen't work, try to another method, do quantazition with .mlmodel)
```diff
- step 4:reduce the model size using tensorflow quantazition

- 1) Installing Bazel on macOS:
-    We will use bazel to build the transform_graph sourcecode
-    https://docs.bazel.build/versions/master/install-os-x.html

- 2）Install the tools that can get the nodes from .pb model
-    https://blog.csdn.net/hh_2018/article/details/82747483
-    bazel build tensorflow/tools/graph_transforms:summarize_graph

- 3) Get the input and output node from .pb model
-    /Users/xiaoyuwang/tensorflow/bazel-bin/tensorflow/tools/graph_transforms/summarize_graph --in_graph=rain_princess_quanti.pb

- 4) install quantazition tools: transform_graph
-    https://www.cnblogs.com/missidiot/p/9869305.html
-    1) get the tensorflow sourcecode
-       git clone https://github.com/tensorflow/tensorflow.git
-    2) build the sourcecode
-       bazel build tensorflow/tools/graph_transforms:transform_graph
-    3) execute the script:
-       step3_quanti.sh
```

### WEEK 6(3.2-3.8)
#### step 4:convert tensorflow .pb model to CoreML using coremltools

1. Install coremltools

   https://pypi.org/project/coremltools/

   pip install coremltools==2.0

2. get the txt file of .pb model

   step3_getpbtxt.sh
   ```python
   python inspect_pb.py rain_princess.pb rain_princess.txt
   ```
   Then we can get the input and output information from the txt file

3. do convert

   /Users/xiaoyuwang/Desktop/capstone/fast-style-transfer/models/rain_princess/step5_pb2coreml.py

   execute the following script:

   step4_pb2coreml.py
   ```python
   import tfcoreml as tf_converter
   import coremltools
   import coremltools.proto.FeatureTypes_pb2 as ft 

   # convert .pb to .mlmodel using tfcoreml
   tf_converter.convert(tf_model_path = 'rain_princess.pb',
                     mlmodel_path = 'rain_princess.mlmodel',
                     input_name_shape_dict={'X_content:0': [1, 256, 256, 3]},
                     output_feature_names = ['add_37:0'])
   Then we get the .mlmodel file
   But when we open the .mlmodel by xcode, we will find that the inputs type and the outputs types are MultiArray. 
   Unfortunately, we can't use it on the swift project. So we need to convert it using the following script:
   # convert MLMultiArray to images
   spec = coremltools.utils.load_spec("rain_princess.mlmodel")
   # inputs
   input = spec.description.input[0]
   input.type.imageType.colorSpace = ft.ImageFeatureType.RGB
   input.type.imageType.height = 256 
   input.type.imageType.width = 256

   # outputs
   output = spec.description.output[0]
   output.type.imageType.colorSpace = ft.ImageFeatureType.RGB
   output.type.imageType.height = 256
   output.type.imageType.width = 256

   coremltools.utils.save_spec(spec, "rain_princess.mlmodel")
   ```

   Then we get the .mlmodel. We can write swift code next step.

#### step 5: quantazition

https://heartbeat.fritz.ai/reducing-coreml2-model-size-by-4x-with-quantization-in-ios12-b1c854651c4

python step5_quanti.py
```python
import sys
import coremltools
from coremltools.models.neural_network.quantization_utils import *

def quantize(file, bits, functions):
    """ 
    Processes a file to quantize it for each bit-per-weight 
    and function listed.
    file : Core ML file to process (example : mymodel.mlmodel)
    bits : Array of bit per weight (example : [16,8,6,4,2,1])
    functions : Array of distribution functions (example : ["linear", "linear_lut", "kmeans"])
    """
    if not file.endswith(".mlmodel"): return # We only consider .mlmodel files
    model_name = file.split(".")[0]
    model = coremltools.models.MLModel(file)
    for function in functions :
        for bit in bits:
            print("--------------------------------------------------------------------")
            print("Processing "+model_name+" for "+str(bit)+"-bits with "+function+" function")
            sys.stdout.flush()
            quantized_model = quantize_weights(model, bit, function)
            sys.stdout.flush()
            quantized_model.author = "Sherry Wang" 
            quantized_model.short_description = str(bit)+"-bit per quantized weight, using "+function+"."
            quantized_model.save(model_name+"_"+function+"_"+str(bit)+".mlmodel")

# Launch quantization
quantize("rain_princess.mlmodel", 
        [16,8,6,2], 
        ["linear"])
```

### WEEK 7(3.9-3.15)
#### step 6:ios development
Demo

### WEEK 8(3.16-3.22)
do quantazition
