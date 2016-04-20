
use "files"
use "json"

class box Bundle
  let log: Log
  let path: FilePath
  let json: JsonDoc = JsonDoc

  new create(path': FilePath, log': Log = LogNone)? =>
    path = path'; log = log'

    let file = OpenFile(path.join("bundle.json")) as File
    let content: String = file.read_string(file.size())
    try json.parse(content) else
      (let err_line, let err_message) = json.parse_report()
      log("JSON error at: " + file.path.path + ":" + err_line.string()
                            + " : " + err_message)
      error
    end

  fun deps(): Iterator[BundleDep] =>
    let deps_array = try (json.data as JsonObject box).data("deps") as JsonArray box
                     else JsonArray
                     end

    object is Iterator[BundleDep]
      let bundle: Bundle = this
      let inner: Iterator[JsonType box] = deps_array.data.values()
      fun ref has_next(): Bool    => inner.has_next()
      fun ref next(): BundleDep^? =>
        BundleDepFactory(bundle, inner.next() as JsonObject box)
    end

  fun fetch() =>
    for dep in deps() do
      try dep.fetch() end
    end
    for dep in deps() do
      // TODO: detect and prevent infinite recursion here.
      try Bundle(FilePath(path, dep.root_path()), log).fetch() end
    end

  fun paths(): Array[String] val =>
    let out = recover trn Array[String] end
    for dep in deps() do
      out.push(dep.packages_path())
    end
    for dep in deps() do
      // TODO: detect and prevent infinite recursion here.
      try out.append(Bundle(FilePath(path, dep.packages_path()), log).paths()) end
    end
    out
