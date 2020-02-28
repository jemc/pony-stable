
primitive _SubdirNameGenerator
  fun apply(path: String): String val ? =>
    let dash_code: U8 = 45
    let path_name_arr =
      recover val
        var acc = Array[U8]
        for char in path.array().values() do
          if _is_alphanum(char) then
            acc.push(char)
          else
            if acc.size() == 0 then
              acc.push(dash_code)
            elseif acc(acc.size() - 1)? != dash_code then
              acc.push(dash_code)
            end
          end
        end
        acc .> append(path.hash().string())
      end
    String.from_array(path_name_arr)

  fun _is_alphanum(c: U8): Bool =>
    let alphanums =
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".array()
    try
      alphanums.find(c)?
      true
    else
      false
    end
