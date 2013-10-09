NODE_BIN := ./node_modules/.bin

CHECK=✔
HR=\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#

build:
	@echo "${HR}"
	@echo "Building assets..."
	@echo "${HR}"
	@${NODE_BIN}/recess --compress _assets/up.less > css/up.css
	@echo "Compiling and Compressing Less and CSS files with Recess... ${CHECK} Done"
	@cat _assets/bootstrapjs/* > js/up.js.tmp
	@cat _assets/up.js >> js/up.js.tmp
	@${NODE_BIN}/uglifyjs js/up.js.tmp > js/up.js
	@rm -rf js/up.js.tmp
	@echo "Compiling and Compressing JS files with uglify-js... ${CHECK} Done"
	@echo "${HR}"
	@echo "Assets successfully built."
	@echo "${HR}"