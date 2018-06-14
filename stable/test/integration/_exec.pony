use "ponytest"
use "files"
use "process"
use "regex"

actor _Exec
  new create(
    h: TestHelper,
    cmdline: String,
    notifier: ProcessNotify iso)
  =>
    try
      let args = cmdline.split_by(" ")
      let path = FilePath(h.env.root as AmbientAuth, "build/release/stable")?
      let vars: Array[String] iso = []
      let auth = h.env.root as AmbientAuth
      let pm: ProcessMonitor = ProcessMonitor(auth, auth, consume notifier,
        path, consume args, consume vars)
      pm.done_writing()
    else
      h.fail("Could not create FilePath!")
    end

class _ExpectClient is ProcessNotify
  let _h: TestHelper
  let _out: Array[String] val
  let _err: Array[String] val
  let _code: I32
  var _status: Bool

  new iso create(
    h: TestHelper,
    stdout': (Array[String] val | None),
    stderr': (Array[String] val | None),
    code': I32)
  =>
    _h = h
    _out = match stdout'
      | None => recover Array[String](0) end
      | let a: Array[String] val => a
      end
    _err = match stderr'
      | None => recover Array[String](0) end
      | let a: Array[String] val => a
      end
    _code = code'
    _status = true

  fun ref stdout(process: ProcessMonitor ref, data: Array[U8] iso) =>
    let out = String.from_array(consume data)

    for exp in _out.values() do
      try
        let r = Regex(exp)?
        _status = _status and _h.assert_no_error({ ()? => r(out)? }, "match RE "+exp)
      else
        _h.fail("stdout matching failed")
        _status = false
      end
    end

  // TODO deduplicate with stdout
  fun ref stderr(process: ProcessMonitor ref, data: Array[U8] iso) =>
    let out = String.from_array(consume data)
    for exp in _err.values() do
      try
        let r = Regex(exp)?
        _status = _status and _h.assert_no_error({ ()? => r(out)? }, "match RE "+exp)
      else
        _h.fail("stderr matching failed")
        _status = false
      end
    end

  fun ref failed(process: ProcessMonitor ref, err: ProcessError) =>
    _h.fail("ProcessError")
    _status = false

  fun ref dispose(process: ProcessMonitor ref, child_exit_code: I32) =>
    let code: I32 = consume child_exit_code
    _status = _status and _h.assert_eq[I32](_code, code)
    _h.complete(_status)
