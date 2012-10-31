srcdir = /home/huixinchen/opensource/pecl/apc
builddir = /home/huixinchen/opensource/pecl/apc
top_srcdir = /home/huixinchen/opensource/pecl/apc
top_builddir = /home/huixinchen/opensource/pecl/apc
EGREP = grep -E
SED = /bin/sed
CONFIGURE_COMMAND = './configure'
CONFIGURE_OPTIONS =
SHLIB_SUFFIX_NAME = so
SHLIB_DL_SUFFIX_NAME = so
ZEND_EXT_TYPE = zend_extension
RE2C = exit 0;
AWK = gawk
shared_objects_apc = apc.lo php_apc.lo apc_cache.lo apc_compile.lo apc_debug.lo apc_fcntl.lo apc_main.lo apc_mmap.lo apc_sem.lo apc_shm.lo apc_pthreadmutex.lo apc_pthreadrwlock.lo apc_spin.lo pgsql_s_lock.lo apc_sma.lo apc_stack.lo apc_zend.lo apc_rfc1867.lo apc_signal.lo apc_pool.lo apc_iterator.lo apc_bin.lo apc_string.lo
PHP_PECL_EXTENSION = apc
APC_SHARED_LIBADD = -lrt
APC_CFLAGS =
PHP_MODULES = $(phplibdir)/apc.la
PHP_ZEND_EX =
all_targets = $(PHP_MODULES) $(PHP_ZEND_EX)
install_targets = install-modules install-headers
prefix = /home/huixinchen/local/php
exec_prefix = $(prefix)
libdir = ${exec_prefix}/lib
prefix = /home/huixinchen/local/php
phplibdir = /home/huixinchen/opensource/pecl/apc/modules
phpincludedir = /home/huixinchen/local/php/include/php
CC = cc
CFLAGS = -g -O0
CFLAGS_CLEAN = $(CFLAGS)
CPP = cc -E
CPPFLAGS = -DHAVE_CONFIG_H
CXX =
CXXFLAGS = -g -O0
CXXFLAGS_CLEAN = $(CXXFLAGS)
EXTENSION_DIR = /home/huixinchen/local/php/lib/php/extensions/debug-non-zts-20060613
PHP_EXECUTABLE = /home/huixinchen/local/php/bin/php
EXTRA_LDFLAGS =
EXTRA_LIBS =
INCLUDES = -I/home/huixinchen/local/php/include/php -I/home/huixinchen/local/php/include/php/main -I/home/huixinchen/local/php/include/php/TSRM -I/home/huixinchen/local/php/include/php/Zend -I/home/huixinchen/local/php/include/php/ext -I/home/huixinchen/local/php/include/php/ext/date/lib
LFLAGS =
LDFLAGS =
SHARED_LIBTOOL =
LIBTOOL = $(SHELL) $(top_builddir)/libtool
SHELL = /bin/sh
INSTALL_HEADERS = ext/apc/apc_serializer.h
mkinstalldirs = $(top_srcdir)/build/shtool mkdir -p
INSTALL = $(top_srcdir)/build/shtool install -c
INSTALL_DATA = $(INSTALL) -m 644

DEFS = -DPHP_ATOM_INC -I$(top_builddir)/include -I$(top_builddir)/main -I$(top_srcdir)
COMMON_FLAGS = $(DEFS) $(INCLUDES) $(EXTRA_INCLUDES) $(CPPFLAGS) $(PHP_FRAMEWORKPATH)

all: $(all_targets) 
	@echo
	@echo "Build complete."
	@echo "Don't forget to run 'make test'."
	@echo
	
build-modules: $(PHP_MODULES) $(PHP_ZEND_EX)

libphp$(PHP_MAJOR_VERSION).la: $(PHP_GLOBAL_OBJS) $(PHP_SAPI_OBJS)
	$(LIBTOOL) --mode=link $(CC) $(CFLAGS) $(EXTRA_CFLAGS) -rpath $(phptempdir) $(EXTRA_LDFLAGS) $(LDFLAGS) $(PHP_RPATHS) $(PHP_GLOBAL_OBJS) $(PHP_SAPI_OBJS) $(EXTRA_LIBS) $(ZEND_EXTRA_LIBS) -o $@
	-@$(LIBTOOL) --silent --mode=install cp $@ $(phptempdir)/$@ >/dev/null 2>&1

libs/libphp$(PHP_MAJOR_VERSION).bundle: $(PHP_GLOBAL_OBJS) $(PHP_SAPI_OBJS)
	$(CC) $(MH_BUNDLE_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS) $(LDFLAGS) $(EXTRA_LDFLAGS) $(PHP_GLOBAL_OBJS:.lo=.o) $(PHP_SAPI_OBJS:.lo=.o) $(PHP_FRAMEWORKS) $(EXTRA_LIBS) $(ZEND_EXTRA_LIBS) -o $@ && cp $@ libs/libphp$(PHP_MAJOR_VERSION).so

install: $(all_targets) $(install_targets)

install-sapi: $(OVERALL_TARGET)
	@echo "Installing PHP SAPI module:       $(PHP_SAPI)"
	-@$(mkinstalldirs) $(INSTALL_ROOT)$(bindir)
	-@if test ! -r $(phptempdir)/libphp$(PHP_MAJOR_VERSION).$(SHLIB_DL_SUFFIX_NAME); then \
		for i in 0.0.0 0.0 0; do \
			if test -r $(phptempdir)/libphp$(PHP_MAJOR_VERSION).$(SHLIB_DL_SUFFIX_NAME).$$i; then \
				$(LN_S) $(phptempdir)/libphp$(PHP_MAJOR_VERSION).$(SHLIB_DL_SUFFIX_NAME).$$i $(phptempdir)/libphp$(PHP_MAJOR_VERSION).$(SHLIB_DL_SUFFIX_NAME); \
				break; \
			fi; \
		done; \
	fi
	@$(INSTALL_IT)

install-modules: build-modules
	@test -d modules && \
	$(mkinstalldirs) $(INSTALL_ROOT)$(EXTENSION_DIR)
	@echo "Installing shared extensions:     $(INSTALL_ROOT)$(EXTENSION_DIR)/"
	@rm -f modules/*.la >/dev/null 2>&1
	@$(INSTALL) modules/* $(INSTALL_ROOT)$(EXTENSION_DIR)

install-headers:
	-@if test "$(INSTALL_HEADERS)"; then \
		for i in `echo $(INSTALL_HEADERS)`; do \
			i=`$(top_srcdir)/build/shtool path -d $$i`; \
			paths="$$paths $(INSTALL_ROOT)$(phpincludedir)/$$i"; \
		done; \
		$(mkinstalldirs) $$paths && \
		echo "Installing header files:          $(INSTALL_ROOT)$(phpincludedir)/" && \
		for i in `echo $(INSTALL_HEADERS)`; do \
			if test "$(PHP_PECL_EXTENSION)"; then \
				src=`echo $$i | $(SED) -e "s#ext/$(PHP_PECL_EXTENSION)/##g"`; \
			else \
				src=$$i; \
			fi; \
			if test -f "$(top_srcdir)/$$src"; then \
				$(INSTALL_DATA) $(top_srcdir)/$$src $(INSTALL_ROOT)$(phpincludedir)/$$i; \
			elif test -f "$(top_builddir)/$$src"; then \
				$(INSTALL_DATA) $(top_builddir)/$$src $(INSTALL_ROOT)$(phpincludedir)/$$i; \
			else \
				(cd $(top_srcdir)/$$src && $(INSTALL_DATA) *.h $(INSTALL_ROOT)$(phpincludedir)/$$i; \
				cd $(top_builddir)/$$src && $(INSTALL_DATA) *.h $(INSTALL_ROOT)$(phpincludedir)/$$i) 2>/dev/null || true; \
			fi \
		done; \
	fi

PHP_TEST_SETTINGS = -d 'open_basedir=' -d 'output_buffering=0' -d 'memory_limit=-1'
PHP_TEST_SHARED_EXTENSIONS =  ` \
	if test "x$(PHP_MODULES)" != "x"; then \
		for i in $(PHP_MODULES)""; do \
			. $$i; $(top_srcdir)/build/shtool echo -n -- " -d extension=$$dlname"; \
		done; \
	fi; \
	if test "x$(PHP_ZEND_EX)" != "x"; then \
		for i in $(PHP_ZEND_EX)""; do \
			. $$i; $(top_srcdir)/build/shtool echo -n -- " -d $(ZEND_EXT_TYPE)=$(top_builddir)/modules/$$dlname"; \
		done; \
	fi`
PHP_DEPRECATED_DIRECTIVES_REGEX = '^(define_syslog_variables|register_(globals|long_arrays)?|safe_mode|magic_quotes_(gpc|runtime|sybase)?|(zend_)?extension(_debug)?(_ts)?)[\t\ ]*='

test: all
	-@if test ! -z "$(PHP_EXECUTABLE)" && test -x "$(PHP_EXECUTABLE)"; then \
		INI_FILE=`$(PHP_EXECUTABLE) -d 'display_errors=stderr' -r 'echo php_ini_loaded_file();' 2> /dev/null`; \
		if test "$$INI_FILE"; then \
			$(EGREP) -h -v $(PHP_DEPRECATED_DIRECTIVES_REGEX) "$$INI_FILE" > $(top_builddir)/tmp-php.ini; \
		else \
			echo > $(top_builddir)/tmp-php.ini; \
		fi; \
		INI_SCANNED_PATH=`$(PHP_EXECUTABLE) -d 'display_errors=stderr' -r '$$a = explode(",\n", trim(php_ini_scanned_files())); echo $$a[0];' 2> /dev/null`; \
		if test "$$INI_SCANNED_PATH"; then \
			INI_SCANNED_PATH=`$(top_srcdir)/build/shtool path -d $$INI_SCANNED_PATH`; \
			$(EGREP) -h -v $(PHP_DEPRECATED_DIRECTIVES_REGEX) "$$INI_SCANNED_PATH"/*.ini >> $(top_builddir)/tmp-php.ini; \
		fi; \
		TEST_PHP_EXECUTABLE=$(PHP_EXECUTABLE) \
		TEST_PHP_SRCDIR=$(top_srcdir) \
		CC="$(CC)" \
			$(PHP_EXECUTABLE) -n -c $(top_builddir)/tmp-php.ini $(PHP_TEST_SETTINGS) $(top_srcdir)/run-tests.php -n -c $(top_builddir)/tmp-php.ini -d extension_dir=$(top_builddir)/modules/ $(PHP_TEST_SHARED_EXTENSIONS) $(TESTS); \
		rm $(top_builddir)/tmp-php.ini; \
	else \
		echo "ERROR: Cannot run tests without CLI sapi."; \
	fi

clean:
	find . -name \*.gcno -o -name \*.gcda | xargs rm -f
	find . -name \*.lo -o -name \*.o | xargs rm -f
	find . -name \*.la -o -name \*.a | xargs rm -f 
	find . -name \*.so | xargs rm -f
	find . -name .libs -a -type d|xargs rm -rf
	rm -f libphp$(PHP_MAJOR_VERSION).la $(SAPI_CLI_PATH) $(OVERALL_TARGET) modules/* libs/*

distclean: clean
	rm -f Makefile config.cache config.log config.status Makefile.objects Makefile.fragments libtool main/php_config.h stamp-h sapi/apache/libphp$(PHP_MAJOR_VERSION).module buildmk.stamp
	$(EGREP) define'.*include/php' $(top_srcdir)/configure | $(SED) 's/.*>//'|xargs rm -f

.PHONY: all clean install distclean test
.NOEXPORT:
apc.lo: /home/huixinchen/opensource/pecl/apc/apc.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc.c -o apc.lo 
php_apc.lo: /home/huixinchen/opensource/pecl/apc/php_apc.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/php_apc.c -o php_apc.lo 
apc_cache.lo: /home/huixinchen/opensource/pecl/apc/apc_cache.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_cache.c -o apc_cache.lo 
apc_compile.lo: /home/huixinchen/opensource/pecl/apc/apc_compile.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_compile.c -o apc_compile.lo 
apc_debug.lo: /home/huixinchen/opensource/pecl/apc/apc_debug.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_debug.c -o apc_debug.lo 
apc_fcntl.lo: /home/huixinchen/opensource/pecl/apc/apc_fcntl.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_fcntl.c -o apc_fcntl.lo 
apc_main.lo: /home/huixinchen/opensource/pecl/apc/apc_main.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_main.c -o apc_main.lo 
apc_mmap.lo: /home/huixinchen/opensource/pecl/apc/apc_mmap.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_mmap.c -o apc_mmap.lo 
apc_sem.lo: /home/huixinchen/opensource/pecl/apc/apc_sem.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_sem.c -o apc_sem.lo 
apc_shm.lo: /home/huixinchen/opensource/pecl/apc/apc_shm.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_shm.c -o apc_shm.lo 
apc_pthreadmutex.lo: /home/huixinchen/opensource/pecl/apc/apc_pthreadmutex.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_pthreadmutex.c -o apc_pthreadmutex.lo 
apc_pthreadrwlock.lo: /home/huixinchen/opensource/pecl/apc/apc_pthreadrwlock.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_pthreadrwlock.c -o apc_pthreadrwlock.lo 
apc_spin.lo: /home/huixinchen/opensource/pecl/apc/apc_spin.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_spin.c -o apc_spin.lo 
pgsql_s_lock.lo: /home/huixinchen/opensource/pecl/apc/pgsql_s_lock.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/pgsql_s_lock.c -o pgsql_s_lock.lo 
apc_sma.lo: /home/huixinchen/opensource/pecl/apc/apc_sma.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_sma.c -o apc_sma.lo 
apc_stack.lo: /home/huixinchen/opensource/pecl/apc/apc_stack.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_stack.c -o apc_stack.lo 
apc_zend.lo: /home/huixinchen/opensource/pecl/apc/apc_zend.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_zend.c -o apc_zend.lo 
apc_rfc1867.lo: /home/huixinchen/opensource/pecl/apc/apc_rfc1867.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_rfc1867.c -o apc_rfc1867.lo 
apc_signal.lo: /home/huixinchen/opensource/pecl/apc/apc_signal.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_signal.c -o apc_signal.lo 
apc_pool.lo: /home/huixinchen/opensource/pecl/apc/apc_pool.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_pool.c -o apc_pool.lo 
apc_iterator.lo: /home/huixinchen/opensource/pecl/apc/apc_iterator.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_iterator.c -o apc_iterator.lo 
apc_bin.lo: /home/huixinchen/opensource/pecl/apc/apc_bin.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_bin.c -o apc_bin.lo 
apc_string.lo: /home/huixinchen/opensource/pecl/apc/apc_string.c
	$(LIBTOOL) --mode=compile $(CC) $(APC_CFLAGS) -I. -I/home/huixinchen/opensource/pecl/apc $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS)  -c /home/huixinchen/opensource/pecl/apc/apc_string.c -o apc_string.lo 
$(phplibdir)/apc.la: ./apc.la
	$(LIBTOOL) --mode=install cp ./apc.la $(phplibdir)

./apc.la: $(shared_objects_apc) $(APC_SHARED_DEPENDENCIES)
	$(LIBTOOL) --mode=link $(CC) $(COMMON_FLAGS) $(CFLAGS_CLEAN) $(EXTRA_CFLAGS) $(LDFLAGS) -o $@ -export-dynamic -avoid-version -prefer-pic -module -rpath $(phplibdir) $(EXTRA_LDFLAGS) $(shared_objects_apc) $(APC_SHARED_LIBADD)

