/*
  +----------------------------------------------------------------------+
  | APC                                                                  |
  +----------------------------------------------------------------------+
  | Copyright (c) 2006-2011 The PHP Group                                |
  +----------------------------------------------------------------------+
  | This source file is subject to version 3.01 of the PHP license,      |
  | that is bundled with this package in the file LICENSE, and is        |
  | available through the world-wide-web at the following url:           |
  | http://www.php.net/license/3_01.txt                                  |
  | If you did not receive a copy of the PHP license and are unable to   |
  | obtain it through the world-wide-web, please send a note to          |
  | license@php.net so we can mail you a copy immediately.               |
  +----------------------------------------------------------------------+
  | Authors: Daniel Cowgill <dcowgill@communityconnect.com>              |
  +----------------------------------------------------------------------+

   This software was contributed to PHP by Community Connect Inc. in 2002
   and revised in 2005 by Yahoo! Inc. to add support for PHP 5.1.
   Future revisions and derivatives of this source code must acknowledge
   Community Connect Inc. as the original contributor of this module by
   leaving this note intact in the source code.

   All other licensing and usage conditions are those of the PHP Group.

 */

/* $Id: apc_zend.c 329499 2013-02-18 23:29:38Z gopalv $ */

#include "apc_zend.h"
#include "apc_globals.h"

/* true global */
int apc_reserved_offset;

void* apc_php_malloc(size_t n TSRMLS_DC)
{
    return emalloc(n);
}

void apc_php_free(void* p TSRMLS_DC)
{
    efree(p);
}

#ifdef APC_OPCODE_OVERRIDE

static opcode_handler_t *apc_original_opcode_handlers;
static opcode_handler_t apc_opcode_handlers[APC_OPCODE_HANDLER_COUNT];

#ifdef ZEND_ENGINE_2_5
#define APC_EX_CV(i) (*EX_CV_NUM(execute_data, i))
#define APC_EX_T(offset) (*EX_TMP_VAR(execute_data, offset))
#else
#define APC_EX_CV(i) execute_data->CVs[i]
#define APC_EX_T(offset) (*(temp_variable *)((char*)execute_data->Ts + offset))
#endif

#ifdef ZEND_ENGINE_2_4
static zval *apc_get_zval_ptr(zend_uchar op_type, znode_op *node, zval **freeval, zend_execute_data *execute_data TSRMLS_DC)
{
    *freeval = NULL;

    switch (op_type) {
        case IS_CONST:
            return node->zv;
        case IS_VAR:
            return APC_EX_T(node->var).var.ptr;
        case IS_TMP_VAR:
            return (*freeval = &APC_EX_T(node->var).tmp_var);
        case IS_CV:
        {
            zval ***ret = &APC_EX_CV(node->var);

            if (!*ret) {
                zend_compiled_variable *cv = &EG(active_op_array)->vars[node->var];

                if (zend_hash_quick_find(EG(active_symbol_table), cv->name, cv->name_len+1, cv->hash_value, (void**)ret)==FAILURE) {
                    apc_notice("Undefined variable: %s" TSRMLS_CC, cv->name);
                    return &EG(uninitialized_zval);
                }
            }
            return **ret;
        }
        case IS_UNUSED:
        default:
            return NULL;
    }
}
#else
static zval *apc_get_zval_ptr(znode *node, zval **freeval, zend_execute_data *execute_data TSRMLS_DC)
{
    *freeval = NULL;

    switch (node->op_type) {
        case IS_CONST:
            return &(node->u.constant);
        case IS_VAR:
            return APC_EX_T(node->u.var).var.ptr;
        case IS_TMP_VAR:
            return (*freeval = &APC_EX_T(node->u.var).tmp_var);
#ifdef ZEND_ENGINE_2_1
        case IS_CV:
        {
            zval ***ret = &APC_EX_CV(node->u.var);

            if (!*ret) {
                zend_compiled_variable *cv = &EG(active_op_array)->vars[node->u.var];

                if (zend_hash_quick_find(EG(active_symbol_table), cv->name, cv->name_len+1, cv->hash_value, (void**)ret)==FAILURE) {
                    apc_notice("Undefined variable: %s" TSRMLS_CC, cv->name);
                    return &EG(uninitialized_zval);
                }
            }
            return **ret;
        }
#endif
        case IS_UNUSED:
        default:
            return NULL;
    }
}
#endif

static int ZEND_FASTCALL apc_op_ZEND_INCLUDE_OR_EVAL(ZEND_OPCODE_HANDLER_ARGS)
{
    APC_ZEND_OPLINE
    zval *freeop1 = NULL;
    zval *inc_filename = NULL, tmp_inc_filename;
    php_stream_wrapper *wrapper;
    char *path_for_open, realpath_storage[MAXPATHLEN], *real_path;
    int ret = 0;
    zend_file_handle file_handle;
    apc_cache_entry_t* cache_entry;

#ifdef ZEND_ENGINE_2_4
    if (opline->extended_value != ZEND_INCLUDE_ONCE &&
        opline->extended_value != ZEND_REQUIRE_ONCE) {
        return apc_original_opcode_handlers[APC_OPCODE_HANDLER_DECODE(opline)](ZEND_OPCODE_HANDLER_ARGS_PASSTHRU);
    }

    inc_filename = apc_get_zval_ptr(opline->op1_type, &opline->op1, &freeop1, execute_data TSRMLS_CC);
#else
    if (Z_LVAL(opline->op2.u.constant) != ZEND_INCLUDE_ONCE &&
        Z_LVAL(opline->op2.u.constant) != ZEND_REQUIRE_ONCE) {
        return apc_original_opcode_handlers[APC_OPCODE_HANDLER_DECODE(opline)](ZEND_OPCODE_HANDLER_ARGS_PASSTHRU);
    }

    inc_filename = apc_get_zval_ptr(&opline->op1, &freeop1, execute_data TSRMLS_CC);
#endif

    if (Z_TYPE_P(inc_filename) != IS_STRING) {
        tmp_inc_filename = *inc_filename;
        zval_copy_ctor(&tmp_inc_filename);
        convert_to_string(&tmp_inc_filename);
        inc_filename = &tmp_inc_filename;
    }

    /* Check to see if this is a regular file and bail if it isn't */
    wrapper = php_stream_locate_url_wrapper(Z_STRVAL_P(inc_filename), &path_for_open, 0 TSRMLS_CC);
    if (wrapper != &php_plain_files_wrapper) {
        if (inc_filename == &tmp_inc_filename) {
            zval_dtor(&tmp_inc_filename);
        }
        return apc_original_opcode_handlers[APC_OPCODE_HANDLER_DECODE(opline)](ZEND_OPCODE_HANDLER_ARGS_PASSTHRU);
    }

    /* 
       Before we do anything else, we can check to see if we have a cached version of this
       file, in which case we can skip the realpath - this also means that we will be checking 
       the correct realpath for this cache entry since it is possible that the inode existed in
       a different directory at the time it was cached. Some deploy systems will do tricky things
       where they rename directories and move a symlink around.
     */
    file_handle.filename = inc_filename->value.str.val;
    file_handle.free_filename = 0;
    file_handle.type = ZEND_HANDLE_FILENAME;
    file_handle.opened_path = NULL;
    file_handle.handle.fp = NULL;
    cache_entry = apc_get_cache_entry(&file_handle TSRMLS_CC);
    if (cache_entry) {
        real_path = cache_entry->data.file.filename;
    } else {
        if (!IS_ABSOLUTE_PATH(path_for_open, strlen(path_for_open)) || !VCWD_REALPATH(path_for_open, realpath_storage)) {
            /* Fallback to original handler */
            if (inc_filename == &tmp_inc_filename) {
                zval_dtor(&tmp_inc_filename);
            }
            return apc_original_opcode_handlers[APC_OPCODE_HANDLER_DECODE(opline)](ZEND_OPCODE_HANDLER_ARGS_PASSTHRU);
        }
        real_path = realpath_storage;
    }

    if (zend_hash_exists(&EG(included_files), real_path, strlen(real_path) + 1)) {
#ifdef ZEND_ENGINE_2_4
        if (!(opline->result_type & EXT_TYPE_UNUSED)) {
            ALLOC_INIT_ZVAL(APC_EX_T(opline->result.var).var.ptr);
            ZVAL_TRUE(APC_EX_T(opline->result.var).var.ptr);
        }
#else
        if (!(opline->result.u.EA.type & EXT_TYPE_UNUSED)) {
            ALLOC_INIT_ZVAL(APC_EX_T(opline->result.u.var).var.ptr);
            ZVAL_TRUE(APC_EX_T(opline->result.u.var).var.ptr);
        }
#endif
        if (inc_filename == &tmp_inc_filename) {
            zval_dtor(&tmp_inc_filename);
        }
        if (freeop1) {
            zval_dtor(freeop1);
        }
        execute_data->opline++;
        return 0;
    }

#ifdef ZEND_ENGINE_2_4
    opline->extended_value = (opline->extended_value == ZEND_INCLUDE_ONCE) ? ZEND_INCLUDE : ZEND_REQUIRE;
    ret = apc_original_opcode_handlers[APC_OPCODE_HANDLER_DECODE(opline)](ZEND_OPCODE_HANDLER_ARGS_PASSTHRU);
    opline->extended_value = (opline->extended_value == ZEND_INCLUDE) ? ZEND_INCLUDE_ONCE : ZEND_REQUIRE_ONCE;
#else
    Z_LVAL(opline->op2.u.constant) = (Z_LVAL(opline->op2.u.constant) == ZEND_INCLUDE_ONCE) ? ZEND_INCLUDE : ZEND_REQUIRE;
    ret = apc_original_opcode_handlers[APC_OPCODE_HANDLER_DECODE(opline)](ZEND_OPCODE_HANDLER_ARGS_PASSTHRU);
    Z_LVAL(opline->op2.u.constant) = (Z_LVAL(opline->op2.u.constant) == ZEND_INCLUDE) ? ZEND_INCLUDE_ONCE : ZEND_REQUIRE_ONCE;
#endif

    return ret;
}

void apc_zend_init(TSRMLS_D)
{
    zend_extension dummy_ext;
    apc_reserved_offset = zend_get_resource_handle(&dummy_ext); 
    assert(apc_reserved_offset == dummy_ext.resource_number);
    assert(apc_reserved_offset != -1);
    assert(sizeof(apc_opflags_t) <= sizeof(void*));
    if (!APCG(include_once)) {
        /* If we're not overriding the INCLUDE_OR_EVAL handler, then just skip this malarkey */
        return;
    }

    memcpy(apc_opcode_handlers, zend_opcode_handlers, sizeof(apc_opcode_handlers));

    /* 5.0 exposes zend_opcode_handlers differently than 5.1 and later */
#ifdef ZEND_ENGINE_2_1
    apc_original_opcode_handlers = zend_opcode_handlers;
    zend_opcode_handlers = apc_opcode_handlers;
#else
    apc_original_opcode_handlers = apc_opcode_handlers;
#endif

    APC_REPLACE_OPCODE(ZEND_INCLUDE_OR_EVAL);
}

void apc_zend_shutdown(TSRMLS_D)
{
    if (!APCG(include_once)) {
        /* Nothing changed, nothing to restore */
        return;
    }

#ifdef ZEND_ENGINE_2_1
    zend_opcode_handlers = apc_original_opcode_handlers;
#else
    memcpy(zend_opcode_handlers, apc_original_opcode_handlers, sizeof(apc_opcode_handlers));
#endif
}

#else /* Opcode Overrides unavailable */

void apc_zend_init(TSRMLS_D) { }
void apc_zend_shutdown(TSRMLS_D) { }

#endif /* APC_OPCODE_OVERRIDE */

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim>600: expandtab sw=4 ts=4 sts=4 fdm=marker
 * vim<600: expandtab sw=4 ts=4 sts=4
 */
