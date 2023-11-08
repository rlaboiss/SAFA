result-elon-musk+original.mp4: result.mp4
	ffmpeg -i assets/02.mp4 -i result.mp4 -filter_complex hstack	\
            result-elon-musk+original.mp4

result.mp4:
	python animation_demo.py --cpu --config config/end2end.yaml	\
            --relative --adapt_scale --find_best_frame			\
            --checkpoint ckpt/final_3DV.tar				\
            --flame_model_dir modules					\
            --source_image_pth assets/elon-musk.png			\
            --driving_video_pth assets/02.mp4

.PHONY: clean
clean:
	rm -f result.mp4 result-elon-musk+original.mp4
