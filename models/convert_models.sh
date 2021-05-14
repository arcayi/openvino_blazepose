# This script has to be run from the docker container started by ./docker_tflite2tensorflow.sh

FP=${1:-FP32}

source /opt/intel/openvino_2021/bin/setupvars.sh

convert_model () {
	model_name=$1
	if [ -z "$2" ]
	then
		arg_mean_values=""
	else
		arg_mean_values="--mean_values ${2}"
	fi
	if [ -z "$3" ]
	then
		arg_scale_values=""
	else
		arg_scale_values="--scale_values ${3}"
	fi
	mean_values=$2
	scale_values=$3
	tflite2tensorflow \
		--model_path ${model_name}.tflite \
		--model_output_path ${model_name} \
		--flatc_path ../../flatc \
		--schema_path ../../schema.fbs \
		--output_pb \
		--optimizing_for_openvino_and_myriad
	# Generate Openvino "non normalized input" models: the normalization has to be mode explictly in the code
	#tflite2tensorflow \
	#  --model_path ${model_name}.tflite \
	#  --model_output_path ${model_name} \
	#  --flatc_path ../../flatc \
	#  --schema_path ../../schema.fbs \
	#  --output_openvino_and_myriad 
	# Generate Openvino "normalized input" models 
	/opt/intel/openvino_2021/deployment_tools/model_optimizer/mo_tf.py \
		--input_model ${model_name}/model_float32.pb \
		--model_name ${model_name}_${FP} \
		--data_type ${FP} \
		${arg_mean_values} \
		${arg_scale_values} \
		--reverse_input_channels
}

convert_model pose_detection "[127.5,127.5,127.5]"  "[127.5,127.5,127.5]"
convert_model pose_landmark_full "" "[255.0,255.0,255.0]"
convert_model pose_landmark_lite "" "[255.0,255.0,255.0]"
convert_model pose_landmark_heavy "" "[255.0,255.0,255.0]"

