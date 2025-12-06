## Http wrap for package 'http'

## Simple get/post/multipart

```dart
  // Get Text
XResult<String> textGet = await httpGet(uri.appendPath("query"), args: ["pruductId" >> 100]).text(utf8);
if(textGet.success){
  println("Text", textGet.value);
}else{
  println("error", textGet.error.message);
}
// Post
XResult<String> textPost = await httpPost(uri.appendPath("query"), args: ["pruductId" >> 100], headers: {"access_token": "xxxxxx"}).text(utf8);

// Post Body
HttpBody body = HttpBody.json("""{"type":"fruit", "name":"Apple"}""");
XResult<String> textPostBody = await httpPost(uri.appendPath("create"), body: body, headers: {"access_token": "xxxxxx"}).text(utf8);

// Multipart, uplaod files
FileItem fileImage = FileItem(field: "image", file: File("..image_path"));
XResult<String> multipartResult = await httpMultipart(uri.appendPath("upload"), files: [fileImage], headers: {"access_token": "xxxxxx"}).text(utf8);
```

## JSON result
* cast/map whole result.
```dart  
// json result, return type is Result<dynamic>
  XResult jr = await httpGet(uri, args: ["pruductId" >> 100]).json();
  // cast to int result
  XResult<int> intResult = jr.casted();
  // to list result
  XResult<List<int>> listResult = jr.mapList((e) => e as int);
  if(listResult.success){
    println(listResult.value)
  }
```
* map value on success.
```dart  
class Product {
  Map<String, dynamic> model;

  Product(this.model);

  int get id => model["id"];

  String get name => model["name"];
}

XResult jr = await httpGet(uri, args: ["pruductId" >> 100]).json();
if(jr.success){
  Product p = jr.model(Product.new);
  // list model
  List<Product> products = jr.listModel(Product.new);
}
```
