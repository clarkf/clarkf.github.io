images/%.png: graphs/%.dot
	dot -Tpng $< -o $@
