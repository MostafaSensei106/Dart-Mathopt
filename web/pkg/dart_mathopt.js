let wasm_bindgen = (function(exports) {
    let script_src;
    if (typeof document !== 'undefined' && document.currentScript !== null) {
        script_src = new URL(document.currentScript.src, location.href).toString();
    }

    //#region exports

    class WorkerPool {
        static __wrap(ptr) {
            const obj = Object.create(WorkerPool.prototype);
            obj.__wbg_ptr = ptr;
            WorkerPoolFinalization.register(obj, obj.__wbg_ptr, obj);
            return obj;
        }
        __destroy_into_raw() {
            const ptr = this.__wbg_ptr;
            this.__wbg_ptr = 0;
            WorkerPoolFinalization.unregister(this);
            return ptr;
        }
        free() {
            const ptr = this.__destroy_into_raw();
            wasm.__wbg_workerpool_free(ptr, 0);
        }
        /**
         * @param {number | null} [initial]
         * @param {string | null} [script_src]
         * @param {string | null} [worker_js_preamble]
         * @param {string | null} [wasm_bindgen_name]
         * @returns {WorkerPool}
         */
        static new(initial, script_src, worker_js_preamble, wasm_bindgen_name) {
            if (!isLikeNone(initial)) {
                _assertNum(initial);
            }
            var ptr0 = isLikeNone(script_src) ? 0 : passStringToWasm0(script_src, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            var len0 = WASM_VECTOR_LEN;
            var ptr1 = isLikeNone(worker_js_preamble) ? 0 : passStringToWasm0(worker_js_preamble, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            var len1 = WASM_VECTOR_LEN;
            var ptr2 = isLikeNone(wasm_bindgen_name) ? 0 : passStringToWasm0(wasm_bindgen_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            var len2 = WASM_VECTOR_LEN;
            const ret = wasm.workerpool_new(isLikeNone(initial) ? Number.MAX_SAFE_INTEGER : (initial) >>> 0, ptr0, len0, ptr1, len1, ptr2, len2);
            if (ret[2]) {
                throw takeFromExternrefTable0(ret[1]);
            }
            return WorkerPool.__wrap(ret[0]);
        }
        /**
         * Creates a new `WorkerPool` which immediately creates `initial` workers.
         *
         * The pool created here can be used over a long period of time, and it
         * will be initially primed with `initial` workers. Currently workers are
         * never released or gc'd until the whole pool is destroyed.
         *
         * # Errors
         *
         * Returns any error that may happen while a JS web worker is created and a
         * message is sent to it.
         * @param {number} initial
         * @param {string} script_src
         * @param {string} worker_js_preamble
         * @param {string} wasm_bindgen_name
         */
        constructor(initial, script_src, worker_js_preamble, wasm_bindgen_name) {
            _assertNum(initial);
            const ptr0 = passStringToWasm0(script_src, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            const len0 = WASM_VECTOR_LEN;
            const ptr1 = passStringToWasm0(worker_js_preamble, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            const len1 = WASM_VECTOR_LEN;
            const ptr2 = passStringToWasm0(wasm_bindgen_name, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
            const len2 = WASM_VECTOR_LEN;
            const ret = wasm.workerpool_new_raw(initial, ptr0, len0, ptr1, len1, ptr2, len2);
            if (ret[2]) {
                throw takeFromExternrefTable0(ret[1]);
            }
            this.__wbg_ptr = ret[0];
            WorkerPoolFinalization.register(this, this.__wbg_ptr, this);
            return this;
        }
    }
    if (Symbol.dispose) WorkerPool.prototype[Symbol.dispose] = WorkerPool.prototype.free;
    exports.WorkerPool = WorkerPool;

    /**
     * @param {number} call_id
     * @param {any} ptr_
     * @param {number} rust_vec_len_
     * @param {number} data_len_
     */
    function frb_dart_fn_deliver_output(call_id, ptr_, rust_vec_len_, data_len_) {
        _assertNum(call_id);
        _assertNum(rust_vec_len_);
        _assertNum(data_len_);
        wasm.frb_dart_fn_deliver_output(call_id, ptr_, rust_vec_len_, data_len_);
    }
    exports.frb_dart_fn_deliver_output = frb_dart_fn_deliver_output;

    /**
     * # Safety
     *
     * This should never be called manually.
     * @param {any} handle
     * @param {any} dart_handler_port
     * @returns {number}
     */
    function frb_dart_opaque_dart2rust_encode(handle, dart_handler_port) {
        const ret = wasm.frb_dart_opaque_dart2rust_encode(handle, dart_handler_port);
        return ret >>> 0;
    }
    exports.frb_dart_opaque_dart2rust_encode = frb_dart_opaque_dart2rust_encode;

    /**
     * @param {number} ptr
     */
    function frb_dart_opaque_drop_thread_box_persistent_handle(ptr) {
        _assertNum(ptr);
        wasm.frb_dart_opaque_drop_thread_box_persistent_handle(ptr);
    }
    exports.frb_dart_opaque_drop_thread_box_persistent_handle = frb_dart_opaque_drop_thread_box_persistent_handle;

    /**
     * @param {number} ptr
     * @returns {any}
     */
    function frb_dart_opaque_rust2dart_decode(ptr) {
        _assertNum(ptr);
        const ret = wasm.frb_dart_opaque_rust2dart_decode(ptr);
        return ret;
    }
    exports.frb_dart_opaque_rust2dart_decode = frb_dart_opaque_rust2dart_decode;

    /**
     * @returns {number}
     */
    function frb_get_rust_content_hash() {
        const ret = wasm.frb_get_rust_content_hash();
        return ret;
    }
    exports.frb_get_rust_content_hash = frb_get_rust_content_hash;

    /**
     * @param {number} func_id
     * @param {any} port_
     * @param {any} ptr_
     * @param {number} rust_vec_len_
     * @param {number} data_len_
     */
    function frb_pde_ffi_dispatcher_primary(func_id, port_, ptr_, rust_vec_len_, data_len_) {
        _assertNum(func_id);
        _assertNum(rust_vec_len_);
        _assertNum(data_len_);
        wasm.frb_pde_ffi_dispatcher_primary(func_id, port_, ptr_, rust_vec_len_, data_len_);
    }
    exports.frb_pde_ffi_dispatcher_primary = frb_pde_ffi_dispatcher_primary;

    /**
     * @param {number} func_id
     * @param {any} ptr_
     * @param {number} rust_vec_len_
     * @param {number} data_len_
     * @returns {any}
     */
    function frb_pde_ffi_dispatcher_sync(func_id, ptr_, rust_vec_len_, data_len_) {
        _assertNum(func_id);
        _assertNum(rust_vec_len_);
        _assertNum(data_len_);
        const ret = wasm.frb_pde_ffi_dispatcher_sync(func_id, ptr_, rust_vec_len_, data_len_);
        return ret;
    }
    exports.frb_pde_ffi_dispatcher_sync = frb_pde_ffi_dispatcher_sync;

    /**
     * ## Safety
     * This function reclaims a raw pointer created by [`TransferClosure`], and therefore
     * should **only** be used in conjunction with it.
     * Furthermore, the WASM module in the worker must have been initialized with the shared
     * memory from the host JS scope.
     * @param {number} payload
     * @param {any[]} transfer
     */
    function receive_transfer_closure(payload, transfer) {
        _assertNum(payload);
        const ptr0 = passArrayJsValueToWasm0(transfer, wasm.__wbindgen_malloc);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.receive_transfer_closure(payload, ptr0, len0);
        if (ret[1]) {
            throw takeFromExternrefTable0(ret[0]);
        }
    }
    exports.receive_transfer_closure = receive_transfer_closure;

    function wasm_start_callback() {
        wasm.wasm_start_callback();
    }
    exports.wasm_start_callback = wasm_start_callback;

    //#endregion

    //#region wasm imports
    function __wbg_get_imports(memory) {
        const import0 = {
            __proto__: null,
            __wbg___wbindgen_debug_string_4687d8d8c2017d52: function(arg0, arg1) {
                const ret = debugString(arg1);
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            },
            __wbg___wbindgen_is_function_1f9d30630b8b1d3d: function(arg0) {
                const ret = typeof(arg0) === 'function';
                _assertBoolean(ret);
                return ret;
            },
            __wbg___wbindgen_is_undefined_8865fb403f8fe9d8: function(arg0) {
                const ret = arg0 === undefined;
                _assertBoolean(ret);
                return ret;
            },
            __wbg___wbindgen_jsval_eq_02babf21faa37971: function(arg0, arg1) {
                const ret = arg0 === arg1;
                _assertBoolean(ret);
                return ret;
            },
            __wbg___wbindgen_memory_caa4a6165639c8b5: function() {
                const ret = wasm.memory;
                return ret;
            },
            __wbg___wbindgen_module_7115fb14045f9891: function() {
                const ret = wasmModule;
                return ret;
            },
            __wbg___wbindgen_number_get_2e0e7dee9f701a71: function(arg0, arg1) {
                const obj = arg1;
                const ret = typeof(obj) === 'number' ? obj : undefined;
                if (!isLikeNone(ret)) {
                    _assertNum(ret);
                }
                getDataViewMemory0().setFloat64(arg0 + 8 * 1, isLikeNone(ret) ? 0 : ret, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, !isLikeNone(ret), true);
            },
            __wbg___wbindgen_rethrow_cb2e88c6b2a16733: function(arg0) {
                throw arg0;
            },
            __wbg___wbindgen_string_get_0380ccaa2f57f0d9: function(arg0, arg1) {
                const obj = arg1;
                const ret = typeof(obj) === 'string' ? obj : undefined;
                var ptr1 = isLikeNone(ret) ? 0 : passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                var len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            },
            __wbg___wbindgen_throw_41e9ee4f547fc59a: function(arg0, arg1) {
                throw new Error(getStringFromWasm0(arg0, arg1));
            },
            __wbg__wbg_cb_unref_dcc1a90847f04c41: function() { return logError(function (arg0) {
                arg0._wbg_cb_unref();
            }, arguments); },
            __wbg_async_9c5ef1f056e09ade: function() { return logError(function (arg0) {
                const ret = arg0.async;
                _assertBoolean(ret);
                return ret;
            }, arguments); },
            __wbg_buffer_7afc7cca4d0cf036: function() { return logError(function (arg0) {
                const ret = arg0.buffer;
                return ret;
            }, arguments); },
            __wbg_call_187d372bd5fdd4aa: function() { return handleError(function (arg0, arg1, arg2) {
                const ret = arg0.call(arg1, arg2);
                return ret;
            }, arguments); },
            __wbg_close_baf8ba6c3102ffc3: function() { return handleError(function (arg0) {
                arg0.close();
            }, arguments); },
            __wbg_createObjectURL_2f3b38279fe61801: function() { return handleError(function (arg0, arg1) {
                const ret = URL.createObjectURL(arg1);
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            }, arguments); },
            __wbg_data_1eb88471f3ec41b4: function() { return logError(function (arg0) {
                const ret = arg0.data;
                return ret;
            }, arguments); },
            __wbg_data_522f7abc70721269: function() { return logError(function (arg0) {
                const ret = arg0.data;
                return ret;
            }, arguments); },
            __wbg_error_757e9472f8410341: function() { return logError(function (arg0, arg1) {
                let deferred0_0;
                let deferred0_1;
                try {
                    deferred0_0 = arg0;
                    deferred0_1 = arg1;
                    console.error(getStringFromWasm0(arg0, arg1));
                } finally {
                    wasm.__wbindgen_free(deferred0_0, deferred0_1, 1);
                }
            }, arguments); },
            __wbg_error_7d496c22586cebef: function() { return logError(function (arg0, arg1) {
                console.error(getStringFromWasm0(arg0, arg1));
            }, arguments); },
            __wbg_eval_2f4f6921d1b0da1a: function() { return handleError(function (arg0, arg1) {
                const ret = eval(getStringFromWasm0(arg0, arg1));
                return ret;
            }, arguments); },
            __wbg_get_31af05bd4842a84f: function() { return handleError(function (arg0, arg1) {
                const ret = Reflect.get(arg0, arg1);
                return ret;
            }, arguments); },
            __wbg_instanceof_BroadcastChannel_3fc6e52c3e8617c8: function() { return logError(function (arg0) {
                let result;
                try {
                    result = arg0 instanceof BroadcastChannel;
                } catch (_) {
                    result = false;
                }
                const ret = result;
                _assertBoolean(ret);
                return ret;
            }, arguments); },
            __wbg_instanceof_ErrorEvent_00c7c57424cd686a: function() { return logError(function (arg0) {
                let result;
                try {
                    result = arg0 instanceof ErrorEvent;
                } catch (_) {
                    result = false;
                }
                const ret = result;
                _assertBoolean(ret);
                return ret;
            }, arguments); },
            __wbg_instanceof_MessageEvent_46c3b0b2da4bd1ab: function() { return logError(function (arg0) {
                let result;
                try {
                    result = arg0 instanceof MessageEvent;
                } catch (_) {
                    result = false;
                }
                const ret = result;
                _assertBoolean(ret);
                return ret;
            }, arguments); },
            __wbg_length_7f3c00c40364105e: function() { return logError(function (arg0) {
                const ret = arg0.length;
                _assertNum(ret);
                return ret;
            }, arguments); },
            __wbg_message_49f5412048473de5: function() { return logError(function (arg0, arg1) {
                const ret = arg1.message;
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            }, arguments); },
            __wbg_name_516a28fed7e0c711: function() { return logError(function (arg0, arg1) {
                const ret = arg1.name;
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            }, arguments); },
            __wbg_new_1dbf7428bba60a42: function() { return logError(function (arg0) {
                const ret = new Uint8Array(arg0);
                return ret;
            }, arguments); },
            __wbg_new_227d7c05414eb861: function() { return logError(function () {
                const ret = new Error();
                return ret;
            }, arguments); },
            __wbg_new_320e2e208176b20f: function() { return logError(function (arg0) {
                const ret = new Int32Array(arg0);
                return ret;
            }, arguments); },
            __wbg_new_5502aad30c185fc8: function() { return logError(function (arg0, arg1) {
                try {
                    var state0 = {a: arg0, b: arg1};
                    var cb0 = (arg0, arg1) => {
                        const a = state0.a;
                        state0.a = 0;
                        try {
                            return wasm_bindgen_bba3e0c74a36907___convert__closures_____invoke___js_sys_959a1de967dac4c9___Function__js_sys_959a1de967dac4c9___Function______true_(a, state0.b, arg0, arg1);
                        } finally {
                            state0.a = a;
                        }
                    };
                    const ret = new Promise(cb0);
                    return ret;
                } finally {
                    state0.a = 0;
                }
            }, arguments); },
            __wbg_new_5fd217af39c6e0ba: function() { return handleError(function (arg0, arg1) {
                const ret = new Worker(getStringFromWasm0(arg0, arg1));
                return ret;
            }, arguments); },
            __wbg_new_617a8cdb8bb1130e: function() { return logError(function () {
                const ret = new Object();
                return ret;
            }, arguments); },
            __wbg_new_abaf2d49bbf44a41: function() { return handleError(function (arg0, arg1) {
                const ret = new BroadcastChannel(getStringFromWasm0(arg0, arg1));
                return ret;
            }, arguments); },
            __wbg_new_ee2291f50781bf1d: function() { return logError(function () {
                const ret = new Array();
                return ret;
            }, arguments); },
            __wbg_new_from_slice_9a868026ffa4208a: function() { return logError(function (arg0, arg1) {
                const ret = new Uint8Array(getArrayU8FromWasm0(arg0, arg1));
                return ret;
            }, arguments); },
            __wbg_new_with_blob_sequence_and_options_3a79963672d74e31: function() { return handleError(function (arg0, arg1) {
                const ret = new Blob(arg0, arg1);
                return ret;
            }, arguments); },
            __wbg_new_worker_a8233ca9ce254a09: function() { return logError(function (arg0, arg1) {
                const ret = new Worker(getStringFromWasm0(arg0, arg1));
                return ret;
            }, arguments); },
            __wbg_now_cace042f68c814d8: function() { return logError(function (arg0) {
                const ret = arg0.now();
                return ret;
            }, arguments); },
            __wbg_now_e7c6795a7f81e10f: function() { return logError(function (arg0) {
                const ret = arg0.now();
                return ret;
            }, arguments); },
            __wbg_of_20798cb14708764f: function() { return logError(function (arg0, arg1) {
                const ret = Array.of(arg0, arg1);
                return ret;
            }, arguments); },
            __wbg_of_dde0b9d3265685ee: function() { return logError(function (arg0, arg1, arg2) {
                const ret = Array.of(arg0, arg1, arg2);
                return ret;
            }, arguments); },
            __wbg_performance_3fcf6e32a7e1ed0a: function() { return logError(function (arg0) {
                const ret = arg0.performance;
                return ret;
            }, arguments); },
            __wbg_performance_5fc5a6563dcd33de: function() { return logError(function (arg0) {
                const ret = arg0.performance;
                return ret;
            }, arguments); },
            __wbg_postMessage_0bd436bcdd35e6a9: function() { return handleError(function (arg0, arg1) {
                arg0.postMessage(arg1);
            }, arguments); },
            __wbg_postMessage_46095c3ed2a3651d: function() { return handleError(function (arg0, arg1) {
                arg0.postMessage(arg1);
            }, arguments); },
            __wbg_postMessage_7dd4fec24fe9919c: function() { return handleError(function (arg0, arg1) {
                arg0.postMessage(arg1);
            }, arguments); },
            __wbg_postMessage_f6c1b76077eb50d7: function() { return handleError(function (arg0, arg1) {
                arg0.postMessage(arg1);
            }, arguments); },
            __wbg_prototypesetcall_bc27214492979395: function() { return logError(function (arg0, arg1, arg2) {
                Uint8Array.prototype.set.call(getArrayU8FromWasm0(arg0, arg1), arg2);
            }, arguments); },
            __wbg_push_2baf45db356cf468: function() { return logError(function (arg0, arg1) {
                const ret = arg0.push(arg1);
                _assertNum(ret);
                return ret;
            }, arguments); },
            __wbg_queueMicrotask_9833f9a49df95a49: function() { return logError(function (arg0) {
                const ret = arg0.queueMicrotask;
                return ret;
            }, arguments); },
            __wbg_queueMicrotask_a72f977e97f23c5f: function() { return logError(function (arg0) {
                queueMicrotask(arg0);
            }, arguments); },
            __wbg_resolve_0076e10020304ede: function() { return logError(function (arg0) {
                const ret = Promise.resolve(arg0);
                return ret;
            }, arguments); },
            __wbg_set_onerror_215573294997c6ba: function() { return logError(function (arg0, arg1) {
                arg0.onerror = arg1;
            }, arguments); },
            __wbg_set_onmessage_2f9c1243dc2af4ec: function() { return logError(function (arg0, arg1) {
                arg0.onmessage = arg1;
            }, arguments); },
            __wbg_set_onmessage_6f8cd76e1fcb9e4e: function() { return logError(function (arg0, arg1) {
                arg0.onmessage = arg1;
            }, arguments); },
            __wbg_set_type_dcf75b2afa60c694: function() { return logError(function (arg0, arg1, arg2) {
                arg0.type = getStringFromWasm0(arg1, arg2);
            }, arguments); },
            __wbg_stack_3b0d974bbf31e44f: function() { return logError(function (arg0, arg1) {
                const ret = arg1.stack;
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            }, arguments); },
            __wbg_static_accessor_GLOBAL_266715b9d96ba635: function() { return logError(function () {
                const ret = typeof global === 'undefined' ? null : global;
                return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
            }, arguments); },
            __wbg_static_accessor_GLOBAL_THIS_10fb7dc1ae063179: function() { return logError(function () {
                const ret = typeof globalThis === 'undefined' ? null : globalThis;
                return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
            }, arguments); },
            __wbg_static_accessor_SELF_0b583911f537483a: function() { return logError(function () {
                const ret = typeof self === 'undefined' ? null : self;
                return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
            }, arguments); },
            __wbg_static_accessor_WINDOW_d7f903d1508cbdc4: function() { return logError(function () {
                const ret = typeof window === 'undefined' ? null : window;
                return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
            }, arguments); },
            __wbg_then_c8a35d4ad59c6b8e: function() { return logError(function (arg0, arg1) {
                const ret = arg0.then(arg1);
                return ret;
            }, arguments); },
            __wbg_then_e71170d78fcf8954: function() { return logError(function (arg0, arg1) {
                const ret = arg0.then(arg1);
                return ret;
            }, arguments); },
            __wbg_timeOrigin_f3d5cb4f4a06c2b7: function() { return logError(function (arg0) {
                const ret = arg0.timeOrigin;
                return ret;
            }, arguments); },
            __wbg_timeOrigin_ff387fd6fb17bb45: function() { return logError(function (arg0) {
                const ret = arg0.timeOrigin;
                return ret;
            }, arguments); },
            __wbg_value_eb2310383eee615b: function() { return logError(function (arg0) {
                const ret = arg0.value;
                return ret;
            }, arguments); },
            __wbg_waitAsync_69490d345f4be40f: function() { return logError(function (arg0, arg1, arg2) {
                const ret = Atomics.waitAsync(arg0, arg1 >>> 0, arg2);
                return ret;
            }, arguments); },
            __wbg_waitAsync_7bc2e34d9ddb004b: function() { return logError(function () {
                const ret = Atomics.waitAsync;
                return ret;
            }, arguments); },
            __wbindgen_generic_0000000000000001: function() { return logError(function (arg0, arg1) {
                // Cast intrinsic for `Closure(Closure { owned: true, function: Function { arguments: [Externref], shim_idx: 30, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
                const ret = makeMutClosure(arg0, arg1, wasm_bindgen_bba3e0c74a36907___convert__closures_____invoke___wasm_bindgen_bba3e0c74a36907___JsValue______true_);
                return ret;
            }, arguments); },
            __wbindgen_generic_0000000000000002: function() { return logError(function (arg0, arg1) {
                // Cast intrinsic for `Closure(Closure { owned: true, function: Function { arguments: [Externref], shim_idx: 321, ret: Result(Unit), inner_ret: Some(Result(Unit)) }, mutable: true }) -> Externref`.
                const ret = makeMutClosure(arg0, arg1, wasm_bindgen_bba3e0c74a36907___convert__closures_____invoke___wasm_bindgen_bba3e0c74a36907___JsValue__core_acc37381b43284e8___result__Result_____wasm_bindgen_bba3e0c74a36907___JsError___true_);
                return ret;
            }, arguments); },
            __wbindgen_generic_0000000000000003: function() { return logError(function (arg0, arg1) {
                // Cast intrinsic for `Closure(Closure { owned: true, function: Function { arguments: [Externref], shim_idx: 323, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
                const ret = makeMutClosure(arg0, arg1, wasm_bindgen_bba3e0c74a36907___convert__closures_____invoke___js_sys_959a1de967dac4c9___futures__task__wait_async_polyfill__MessageEvent______true_);
                return ret;
            }, arguments); },
            __wbindgen_generic_0000000000000004: function() { return logError(function (arg0, arg1) {
                // Cast intrinsic for `Closure(Closure { owned: true, function: Function { arguments: [NamedExternref("Event")], shim_idx: 154, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
                const ret = makeMutClosure(arg0, arg1, wasm_bindgen_bba3e0c74a36907___convert__closures_____invoke___web_sys_630400478319f22d___features__gen_Event__Event______true_);
                return ret;
            }, arguments); },
            __wbindgen_generic_0000000000000005: function() { return logError(function (arg0, arg1) {
                // Cast intrinsic for `Closure(Closure { owned: true, function: Function { arguments: [], shim_idx: 153, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
                const ret = makeMutClosure(arg0, arg1, wasm_bindgen_bba3e0c74a36907___convert__closures_____invoke_______true_);
                return ret;
            }, arguments); },
            __wbindgen_generic_0000000000000006: function() { return logError(function (arg0) {
                // Cast intrinsic for `F64 -> Externref`.
                const ret = arg0;
                return ret;
            }, arguments); },
            __wbindgen_generic_0000000000000007: function() { return logError(function (arg0, arg1) {
                // Cast intrinsic for `Ref(String) -> Externref`.
                const ret = getStringFromWasm0(arg0, arg1);
                return ret;
            }, arguments); },
            __wbindgen_init_externref_table: function() {
                const table = wasm.__wbindgen_externrefs;
                const offset = table.grow(4);
                table.set(0, undefined);
                table.set(offset + 0, undefined);
                table.set(offset + 1, null);
                table.set(offset + 2, true);
                table.set(offset + 3, false);
            },
            __wbindgen_link_e38beab8ec056ba2: function() { return logError(function (arg0) {
                const val = `onmessage = function (ev) {
                    let [ia, index, value] = ev.data;
                    ia = new Int32Array(ia.buffer);
                    let result = Atomics.wait(ia, index, value);
                    postMessage(result);
                };
                `;
                const ret = typeof URL.createObjectURL === 'undefined' ? "data:application/javascript," + encodeURIComponent(val) : URL.createObjectURL(new Blob([val], { type: "text/javascript" }));
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            }, arguments); },
            memory: memory || new WebAssembly.Memory({initial:22,maximum:16384,shared:true}),
        };
        return {
            __proto__: null,
            "./dart_mathopt_bg.js": import0,
        };
    }


    //#endregion
    function wasm_bindgen_bba3e0c74a36907___convert__closures_____invoke_______true_(arg0, arg1) {
        _assertNum(arg0);
        _assertNum(arg1);
        wasm.wasm_bindgen_bba3e0c74a36907___convert__closures_____invoke_______true_(arg0, arg1);
    }

    function wasm_bindgen_bba3e0c74a36907___convert__closures_____invoke___wasm_bindgen_bba3e0c74a36907___JsValue______true_(arg0, arg1, arg2) {
        _assertNum(arg0);
        _assertNum(arg1);
        wasm.wasm_bindgen_bba3e0c74a36907___convert__closures_____invoke___wasm_bindgen_bba3e0c74a36907___JsValue______true_(arg0, arg1, arg2);
    }

    function wasm_bindgen_bba3e0c74a36907___convert__closures_____invoke___js_sys_959a1de967dac4c9___futures__task__wait_async_polyfill__MessageEvent______true_(arg0, arg1, arg2) {
        _assertNum(arg0);
        _assertNum(arg1);
        wasm.wasm_bindgen_bba3e0c74a36907___convert__closures_____invoke___js_sys_959a1de967dac4c9___futures__task__wait_async_polyfill__MessageEvent______true_(arg0, arg1, arg2);
    }

    function wasm_bindgen_bba3e0c74a36907___convert__closures_____invoke___web_sys_630400478319f22d___features__gen_Event__Event______true_(arg0, arg1, arg2) {
        _assertNum(arg0);
        _assertNum(arg1);
        wasm.wasm_bindgen_bba3e0c74a36907___convert__closures_____invoke___web_sys_630400478319f22d___features__gen_Event__Event______true_(arg0, arg1, arg2);
    }

    function wasm_bindgen_bba3e0c74a36907___convert__closures_____invoke___wasm_bindgen_bba3e0c74a36907___JsValue__core_acc37381b43284e8___result__Result_____wasm_bindgen_bba3e0c74a36907___JsError___true_(arg0, arg1, arg2) {
        _assertNum(arg0);
        _assertNum(arg1);
        const ret = wasm.wasm_bindgen_bba3e0c74a36907___convert__closures_____invoke___wasm_bindgen_bba3e0c74a36907___JsValue__core_acc37381b43284e8___result__Result_____wasm_bindgen_bba3e0c74a36907___JsError___true_(arg0, arg1, arg2);
        if (ret[1]) {
            throw takeFromExternrefTable0(ret[0]);
        }
    }

    function wasm_bindgen_bba3e0c74a36907___convert__closures_____invoke___js_sys_959a1de967dac4c9___Function__js_sys_959a1de967dac4c9___Function______true_(arg0, arg1, arg2, arg3) {
        _assertNum(arg0);
        _assertNum(arg1);
        wasm.wasm_bindgen_bba3e0c74a36907___convert__closures_____invoke___js_sys_959a1de967dac4c9___Function__js_sys_959a1de967dac4c9___Function______true_(arg0, arg1, arg2, arg3);
    }

    const WorkerPoolFinalization = (typeof FinalizationRegistry === 'undefined')
        ? { register: () => {}, unregister: () => {} }
        : new FinalizationRegistry(ptr => wasm.__wbg_workerpool_free(ptr, 1));


    //#region intrinsics
    function addToExternrefTable0(obj) {
        const idx = wasm.__externref_table_alloc();
        wasm.__wbindgen_externrefs.set(idx, obj);
        return idx;
    }

    function _assertBoolean(n) {
        if (typeof(n) !== 'boolean') {
            throw new Error(`expected a boolean argument, found ${typeof(n)}`);
        }
    }

    function _assertNum(n) {
        if (typeof(n) !== 'number') throw new Error(`expected a number argument, found ${typeof(n)}`);
    }

    const CLOSURE_DTORS = (typeof FinalizationRegistry === 'undefined')
        ? { register: () => {}, unregister: () => {} }
        : new FinalizationRegistry(state => wasm.__wbindgen_destroy_closure(state.a, state.b));

    function debugString(val) {
        // primitive types
        const type = typeof val;
        if (type == 'number' || type == 'boolean' || val == null) {
            return  `${val}`;
        }
        if (type == 'string') {
            return `"${val}"`;
        }
        if (type == 'symbol') {
            const description = val.description;
            if (description == null) {
                return 'Symbol';
            } else {
                return `Symbol(${description})`;
            }
        }
        if (type == 'function') {
            const name = val.name;
            if (typeof name == 'string' && name.length > 0) {
                return `Function(${name})`;
            } else {
                return 'Function';
            }
        }
        // objects
        if (Array.isArray(val)) {
            const length = val.length;
            let debug = '[';
            if (length > 0) {
                debug += debugString(val[0]);
            }
            for(let i = 1; i < length; i++) {
                debug += ', ' + debugString(val[i]);
            }
            debug += ']';
            return debug;
        }
        // Test for built-in
        const builtInMatches = /\[object ([^\]]+)\]/.exec(toString.call(val));
        let className;
        if (builtInMatches && builtInMatches.length > 1) {
            className = builtInMatches[1];
        } else {
            // Failed to match the standard '[object ClassName]'
            return toString.call(val);
        }
        if (className == 'Object') {
            // we're a user defined class or Object
            // JSON.stringify avoids problems with cycles, and is generally much
            // easier than looping through ownProperties of `val`.
            try {
                return 'Object(' + JSON.stringify(val) + ')';
            } catch (_) {
                return 'Object';
            }
        }
        // errors
        if (val instanceof Error) {
            return `${val.name}: ${val.message}\n${val.stack}`;
        }
        // TODO we could test for more things here, like `Set`s and `Map`s.
        return className;
    }

    function getArrayU8FromWasm0(ptr, len) {
        ptr = ptr >>> 0;
        return getUint8ArrayMemory0().subarray(ptr / 1, ptr / 1 + len);
    }

    let cachedDataViewMemory0 = null;
    function getDataViewMemory0() {
        if (cachedDataViewMemory0 === null || cachedDataViewMemory0.buffer !== wasm.memory.buffer) {
            cachedDataViewMemory0 = new DataView(wasm.memory.buffer);
        }
        return cachedDataViewMemory0;
    }

    function getStringFromWasm0(ptr, len) {
        return decodeText(ptr >>> 0, len);
    }

    let cachedUint8ArrayMemory0 = null;
    function getUint8ArrayMemory0() {
        if (cachedUint8ArrayMemory0 === null || cachedUint8ArrayMemory0.buffer !== wasm.memory.buffer) {
            cachedUint8ArrayMemory0 = new Uint8Array(wasm.memory.buffer);
        }
        return cachedUint8ArrayMemory0;
    }

    function handleError(f, args) {
        try {
            return f.apply(this, args);
        } catch (e) {
            const idx = addToExternrefTable0(e);
            wasm.__wbindgen_exn_store(idx);
        }
    }

    function isLikeNone(x) {
        return x === undefined || x === null;
    }

    function logError(f, args) {
        try {
            return f.apply(this, args);
        } catch (e) {
            let error = (function () {
                try {
                    return e instanceof Error ? `${e.message}\n\nStack:\n${e.stack}` : e.toString();
                } catch(_) {
                    return "<failed to stringify thrown value>";
                }
            }());
            console.error("wasm-bindgen: imported JS function that was not marked as `catch` threw an error:", error);
            throw e;
        }
    }

    function makeMutClosure(arg0, arg1, f) {
        const state = { a: arg0, b: arg1, cnt: 1 };
        const real = (...args) => {

            // First up with a closure we increment the internal reference
            // count. This ensures that the Rust closure environment won't
            // be deallocated while we're invoking it.
            state.cnt++;
            const a = state.a;
            state.a = 0;
            try {
                return f(a, state.b, ...args);
            } finally {
                state.a = a;
                real._wbg_cb_unref();
            }
        };
        real._wbg_cb_unref = () => {
            if (--state.cnt === 0) {
                wasm.__wbindgen_destroy_closure(state.a, state.b);
                state.a = 0;
                CLOSURE_DTORS.unregister(state);
            }
        };
        CLOSURE_DTORS.register(real, state, state);
        return real;
    }

    function passArrayJsValueToWasm0(array, malloc) {
        const ptr = malloc(array.length * 4, 4) >>> 0;
        for (let i = 0; i < array.length; i++) {
            const add = addToExternrefTable0(array[i]);
            getDataViewMemory0().setUint32(ptr + 4 * i, add, true);
        }
        WASM_VECTOR_LEN = array.length;
        return ptr;
    }

    function passStringToWasm0(arg, malloc, realloc) {
        if (typeof(arg) !== 'string') throw new Error(`expected a string argument, found ${typeof(arg)}`);
        if (realloc === undefined) {
            const buf = cachedTextEncoder.encode(arg);
            const ptr = malloc(buf.length, 1) >>> 0;
            getUint8ArrayMemory0().subarray(ptr, ptr + buf.length).set(buf);
            WASM_VECTOR_LEN = buf.length;
            return ptr;
        }

        let len = arg.length;
        let ptr = malloc(len, 1) >>> 0;

        const mem = getUint8ArrayMemory0();

        let offset = 0;

        for (; offset < len; offset++) {
            const code = arg.charCodeAt(offset);
            if (code > 0x7F) break;
            mem[ptr + offset] = code;
        }
        if (offset !== len) {
            if (offset !== 0) {
                arg = arg.slice(offset);
            }
            ptr = realloc(ptr, len, len = offset + arg.length * 3, 1) >>> 0;
            const view = getUint8ArrayMemory0().subarray(ptr + offset, ptr + len);
            const ret = cachedTextEncoder.encodeInto(arg, view);
            if (ret.read !== arg.length) throw new Error('failed to pass whole string');
            offset += ret.written;
            ptr = realloc(ptr, len, offset, 1) >>> 0;
        }

        WASM_VECTOR_LEN = offset;
        return ptr;
    }

    function takeFromExternrefTable0(idx) {
        const value = wasm.__wbindgen_externrefs.get(idx);
        wasm.__externref_table_dealloc(idx);
        return value;
    }

    let cachedTextDecoder = (typeof TextDecoder !== 'undefined' ? new TextDecoder('utf-8', { ignoreBOM: true, fatal: true }) : undefined);
    if (cachedTextDecoder) cachedTextDecoder.decode();

    function decodeText(ptr, len) {
        return cachedTextDecoder.decode(getUint8ArrayMemory0().slice(ptr, ptr + len));
    }

    const cachedTextEncoder = (typeof TextEncoder !== 'undefined' ? new TextEncoder() : undefined);

    if (cachedTextEncoder) {
        cachedTextEncoder.encodeInto = function (arg, view) {
            const buf = cachedTextEncoder.encode(arg);
            view.set(buf);
            return {
                read: arg.length,
                written: buf.length
            };
        };
    }

    let WASM_VECTOR_LEN = 0;


    //#endregion

    //#region wasm loading
    let wasmModule, wasmInstance, wasm;
    function __wbg_finalize_init(instance, module, thread_stack_size) {
        wasmInstance = instance;
        wasm = instance.exports;
        wasmModule = module;
        cachedDataViewMemory0 = null;
        cachedUint8ArrayMemory0 = null;
        if (typeof thread_stack_size !== 'undefined' && (typeof thread_stack_size !== 'number' || thread_stack_size === 0 || thread_stack_size % 65536 !== 0)) {
            throw new Error('invalid stack size');
        }

        wasm.__wbindgen_start(thread_stack_size);
        return wasm;
    }

    async function __wbg_load(module, imports) {
        if (typeof Response === 'function' && module instanceof Response) {
            if (!module.ok) {
                throw new Error(`failed to fetch Wasm: ${module.status} ${module.statusText} fetching '${module.url}'`);
            }

            if (typeof WebAssembly.instantiateStreaming === 'function') {
                try {
                    return await WebAssembly.instantiateStreaming(module, imports);
                } catch (e) {
                    const validResponse = expectedResponseType(module.type);

                    if (validResponse && module.headers.get('Content-Type') !== 'application/wasm') {
                        console.warn("`WebAssembly.instantiateStreaming` failed because your server does not serve Wasm with `application/wasm` MIME type. Falling back to `WebAssembly.instantiate` which is slower. Original error:\n", e);

                    } else { throw e; }
                }
            }

            const bytes = await module.arrayBuffer();
            return await WebAssembly.instantiate(bytes, imports);
        } else {
            const instance = await WebAssembly.instantiate(module, imports);

            if (instance instanceof WebAssembly.Instance) {
                return { instance, module };
            } else {
                return instance;
            }
        }

        function expectedResponseType(type) {
            switch (type) {
                case 'basic': case 'cors': case 'default': return true;
            }
            return false;
        }
    }

    function initSync(module, memory) {
        if (wasm !== undefined) return wasm;

        let thread_stack_size
        if (module !== undefined) {
            if (Object.getPrototypeOf(module) === Object.prototype) {
                ({module, memory, thread_stack_size} = module)
            } else {
                console.warn('using deprecated parameters for `initSync()`; pass a single object instead')
            }
        }

        const imports = __wbg_get_imports(memory);
        if (!(module instanceof WebAssembly.Module)) {
            module = new WebAssembly.Module(module);
        }
        const instance = new WebAssembly.Instance(module, imports);
        return __wbg_finalize_init(instance, module, thread_stack_size);
    }

    async function __wbg_init(module_or_path, memory) {
        if (wasm !== undefined) return wasm;

        let thread_stack_size
        if (module_or_path !== undefined) {
            if (Object.getPrototypeOf(module_or_path) === Object.prototype) {
                ({module_or_path, memory, thread_stack_size} = module_or_path)
            } else {
                console.warn('using deprecated parameters for the initialization function; pass a single object instead')
            }
        }

        if (module_or_path === undefined && script_src !== undefined) {
            module_or_path = script_src.replace(/\.js$/, "_bg.wasm");
        }
        const imports = __wbg_get_imports(memory);

        if (typeof module_or_path === 'string' || (typeof Request === 'function' && module_or_path instanceof Request) || (typeof URL === 'function' && module_or_path instanceof URL)) {
            module_or_path = fetch(module_or_path);
        }

        const { instance, module } = await __wbg_load(await module_or_path, imports);

        return __wbg_finalize_init(instance, module, thread_stack_size);
    }

    //#endregion
    exports.__wasm = wasm;
    return Object.assign(__wbg_init, { initSync }, exports);
})({ __proto__: null });
