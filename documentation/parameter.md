### More Explanation for `param` and `schema_info`

#### param_type (param_location)
OpenAPI 3.0 distinguishes between the following parameter types based on the parameter location: 
**header, path, query, cookie**. [more](https://swagger.io/docs/specification/describing-parameters/)

#### name (param_name)
The name of parameter. It can be Symbol or String.

If param_type is :path, it must correspond to the associated path segment form 
the routing path, for example: if the API path is `/good/:id`, you have to declare a path parameter with name `id` to it.

#### type (schema_type)
Parameter's (schema) type. We call it `schema_type` because it is inside SchemaObj.

Support all [data types](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#dataTypes) defined in OAS.   

In addition, you can use `format` in schema_info to define in fine detail the data type being used, like: 
int32, float, date ...  
All the types you can use as following:
  - **String, 'binary', 'base64'**
  - **Integer, Long, 'int32', 'int64', Float, Double**
  - **File** (it will be converted to `{ type: 'string', format: Config.file_format }`)
  - **Date, DateTime**
  - **Boolean**
  - **Array**: `Array[String]` or `[String]`
  - Nested Array: `[[[Integer]]]`
  - **Object**: you can use just `Object`, or use a hash to declare its properties `{ id!: Integer, name: String }` 
  (`!` bang key means it is required).
  - Nested Object: `{ id!: Integer, name: { first: String, last: String } }`
  - Nested Array and Object: `[[{ id!: Integer, name: { first: String, last: String } }]]`
  - **:ComponentKey**: pass **Symbol** value to type will generate a Schema Reference Object link 
  to the component correspond to ComponentKey, like: :IdPath, :NameQuery
  
  You can use `Object.const_set()` to define a constant that does not exist, but note that 
  the value you set could not be a Symbol (it will be explained as a Ref Object), should be a String.

#### required
 :opt or :req

#### Schema Hash

The [[schema]](https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.0.md#schemaObject) defining the type used for the parameter. 
schema_info(optional) will be used to generate Schema Object inside Parameter Object.  
[source code](https://github.com/zhandao/zero-rails_openapi/blob/master/lib/oas_objs/schema_obj.rb)  
You can set the schema by following keys (all are optional), the words in parentheses are available aliases of the keys:  
  - **enum (values, allowable_values)**  
  Must be Array or Range(will be converted to Array)
  - **must_be (value, allowable_value)**  
  Single value, could be a String, Array ...  
  - **range (number_range)**  
  Allow value in this continuous range. Set this field like this: `{ gt: 0, le: 5 }`
  - **length (lth)**  
  Must be an Integer, Integer Array, Integer Range, or the following format Symbol: `:gt_`, `:ge_`, `:lt_`, `:le_`, examples: :ge_5 means "greater than or equal 5"; :lt_9 means "lower than 9".
  - **format (fmt)**
  - **is (is_a)**  
    1. It's not in OAS, just an addition field for better express.You can see it as `format`, but in fact they are quite different.  
    2. Look at this example: the `format` is set to "int32", but you also want to express that this 
    schema is an "id" format —— this cannot be expressed in the current OAS version.  
    3. So I suggest that the value of `format` should related to data type, `is` should be an entity.  
    4. ZRO defaults to identify whether `is` patterns matched the name, then automatically generate `is`. 
    for example the parameter name "user_email" will generate "is: email". Default `is` options are:  
    [email phone password uuid uri url time date], to overwrite it you can set it in initializer `c.is_options = %w[]`.
    5. If type is Object, for describing each property's schema, the only way is use ref type, like: `{ id: :Id, name: :Name }`
  - **pattern (regexp, pr, reg)**  
  Regexp or Time Format
  - **default (dft, default_value)**
  - **as** # TODO
