# This script has to be run from the docker container started by ./docker_tflite2tensorflow.sh

FP=${1:-FP32}

source /opt/intel/openvino_2021/bin/setupvars.sh

replace () { # Replace in file $1 occurences of the string $2 by $3
	sed "s/${2}/${3}/" $1 > tmpf
	mv tmpf $1
}

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
	# tflite2tensorflow \
	# 	--model_path ${model_name}.tflite \
	# 	--model_output_path ${model_name} \
	# 	--flatc_path ../../flatc \
	# 	--schema_path ../../schema.fbs \
	# 	--output_pb \
	# 	--optimizing_for_openvino_and_myriad

	tflite2tensorflow \
		--model_path ${model_name}.tflite \
		--model_output_path ${model_name} \
		--flatc_path  ../../flatc \
		--schema_path ../../schema.fbs \
		--output_pb

	tflite2tensorflow \
		--model_path ${model_name}.tflite \
		--model_output_path ${model_name} \
		--flatc_path  ../../flatc \
		--schema_path ../../schema.fbs \
		--output_no_quant_float32_tflite \
		--output_dynamic_range_quant_tflite \
		--output_weight_quant_tflite \
		--output_float16_quant_tflite \
		--output_integer_quant_tflite \
		--string_formulas_for_normalization 'data / 255.0' \
		--output_tfjs \
		--output_coreml \
		--output_tftrt_float32 \
		--output_tftrt_float16 \
		--output_onnx \
		--onnx_opset 11

	# python3 -m tf2onnx.convert \
	# 	--opset 11 \
	# 	--tflite ${model_name}/${model_name}.tflite \
	# 	--output ${model_name}/${model_name}.onnx \
	# 	--inputs-as-nchw input_1:0

	# For generating Openvino "non normalized input" models (the normalization would need to be made explictly in the code):
	#tflite2tensorflow \
	#  --model_path ${model_name}.tflite \
	#  --model_output_path ${model_name} \
	#  --flatc_path ../../flatc \
	#  --schema_path ../../schema.fbs \
	#  --output_openvino_and_myriad 
	
	
	# # Generate Openvino "normalized input" models 
	# /opt/intel/openvino_2021/deployment_tools/model_optimizer/mo_tf.py \
	# 	--saved_model_dir ${model_name} \
	# 	--model_name ${model_name}_${FP} \
	# 	--data_type ${FP} \
	# 	${arg_mean_values} \
	# 	${arg_scale_values} \
	# 	--reverse_input_channels
}

convert_model pose_detection "[127.5,127.5,127.5]"  "[127.5,127.5,127.5]"
convert_model pose_landmark_full "" ""
convert_model pose_landmark_lite "" ""
convert_model pose_landmark_heavy "" ""

# Strangely the output layer names are not consistent through the mediapipe landmark models
# Lite model uses : output_poseflag, output_segmentation, output_heatmap, world_3d, ld_3d
# Whereas full and heavy models use: Identity_1, Identity_2, Identity_3, Identity_4 and Identity
# So we modify the xml files for full and heavy models to use the same name as for the lite model
# It makes our life easier later in the code.

# for f in pose_landmark_full_${FP}.xml pose_landmark_heavy_${FP}.xml
# do
# 	replace $f Identity_1 output_poseflag
# 	replace $f Identity_2 output_segmentation
# 	replace $f Identity_3 output_heatmap
# 	replace $f Identity_4 world_3d
# 	replace $f Identity ld_3d
# done


# For Interpolate layers, replace in coordinate_transformation_mode, "half_pixel" by "align_corners"  (bug optimizer)

# for f in pose_landmark_full_${FP}.xml pose_landmark_heavy_${FP}.xml pose_landmark_lite_${FP}.xml
# do
#         replace $f half_pixel align_corners
# done
