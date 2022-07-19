.PHONY: build clean default serve

DEPS = static/style.css static/favicon.ico static/fonts

default: build

static/style.css: less/index.less
	lessc \
		--verbose \
		--math=always \
		--source-map=$@.map \
		$< \
		$@

static/fonts: $(wildcard less/nixos-common-styles/fonts/*.ttf)
	mkdir -p $@
	cp less/nixos-common-styles/fonts/*.ttf $@

static/favicon.png: static/images/logo.png
	convert \
		-resize 16x16 \
		-background none \
		-gravity center \
		-extent 16x16 \
		static/images/logo.png \
		static/favicon.png

static/favicon.ico: static/favicon.png
	convert \
		-resize x16 \
		-gravity center \
		-crop 16x16+0+0 \
		-flatten \
		-colors 256 \
		-background transparent \
		static/favicon.png \
		static/favicon.ico

build: public

public: ${DEPS}
	zola build

serve: ${DEPS}
	zola serve

clean:
	rm -f \
		static/favicon.ico \
		static/favicon.png \
		static/style.css
