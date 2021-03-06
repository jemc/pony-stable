use "ponytest"
use "files"
use "process"
//use "regex"

actor _Exec
  new create(
    h: TestHelper,
    cmdline: String,
    tmp: String,
    notifier: ProcessNotify iso)
  =>
    let stable_bin =
      try
         _env_var(h.env.vars, "STABLE_BIN")?
      else
        h.fail("STABLE_BIN not set")
        h.complete(false)
        return
      end
    try
      let args = cmdline.split_by(" ")
      let path = FilePath(h.env.root as AmbientAuth,
        "stable/test/integration/helper.sh")?
      let auth = h.env.root as AmbientAuth
      let vars: Array[String] iso = [
        "CWD=" + tmp
        "STABLE_BIN=" + stable_bin
        ]
      let pm: ProcessMonitor = ProcessMonitor(auth, auth, consume notifier,
        path, consume args, consume vars)
      pm.done_writing()
      h.dispose_when_done(pm)
    else
      h.fail("Could not create FilePath!")
      h.complete(false)
    end

  fun _env_var(vars: Array[String] val, key: String): String ? =>
    for v in vars.values() do
      if v.contains(key) then
        return v.substring(
          ISize.from[USize](key.size()) + 1,
          ISize.from[USize](v.size()))
      end
    end

    error

class _ExpectClient is ProcessNotify
  let _h: TestHelper
  let _out: Array[String] val
  let _err: Array[String] val
  let _code: I32

  var _status: Bool = true
  var _stdout: String = ""
  var _stderr: String = ""

  new iso create(
    h: TestHelper,
    stdout': (Array[String] val | None),
    stderr': (Array[String] val | None),
    code': I32)
  =>
    _h = h
    _out =
      match stdout'
      | None => []
      | let a: Array[String] val => a
      end
    _err =
      match stderr'
      | None => []
      | let a: Array[String] val => a
      end
    _code = code'

  fun ref stdout(process: ProcessMonitor ref, data: Array[U8] iso) =>
    _stdout = _stdout.add(String.from_array(consume data))

  fun ref stderr(process: ProcessMonitor ref, data: Array[U8] iso) =>
    _stderr = _stderr.add(String.from_array(consume data))

  fun ref failed(process: ProcessMonitor ref, err: ProcessError) =>
    _h.fail("ProcessError")
    _h.complete(false)

  fun ref dispose(process: ProcessMonitor ref, child_exit_code: I32) =>
    let code: I32 = consume child_exit_code
    _status = _status and _h.assert_eq[I32](_code, code)
    //_match_expectations("stdout", _out, _stdout)
    //_match_expectations("stderr", _err, _stderr)
    _h.complete(_status)

  /*fun ref _match_expectations(
    stream: String,
    exps: Array[String] val,
    output: String)
  =>
    for exp in exps.values() do
      try
        let r = Regex(exp)?
        _status = _status and _h.assert_no_error({ ()? => r(output)? },
          stream + " match RE: " + exp)
        _h.log(stream + " was: " + output)
      else
        _h.fail(stream + " regexp failed to compile")
        _status = false
      end
    end*/
