## Http wrap for package 'http'

## Simple get/post/multipart

```dart
  // Get Text
Result<String> textGet = await httpGet(uri.appendPath("query"), args: ["pruductId" >> 100]).text(utf8);
switch (textGet) {
  case Success<String> ok:
    println("Text", ok.value);
    println("Headers", ok.extra);
  case Failure e:
    println("error: ", e);
}
// Post
Result<String> textPost = await httpPost(uri.appendPath("query"), args: ["pruductId" >> 100], headers: {"access_token": "xxxxxx"}).text(utf8);

// Post Body
HttpBody body = HttpBody.json("""{"type":"fruit", "name":"Apple"}""");
Result<String> textPostBody = await httpPost(uri.appendPath("create"), body: body, headers: {"access_token": "xxxxxx"}).text(utf8);

// Multipart, uplaod files
FileItem fileImage = FileItem(field: "image", file: File("..image_path"));
Result<String> multipartResult = await httpMultipart(uri.appendPath("upload"), files: [fileImage], headers: {"access_token": "xxxxxx"}).text(utf8);
```

## JSON result
* cast/map whole result.
```dart  
// json result, return type is Result<dynamic>
  Result jr = await httpGet(uri, args: ["pruductId" >> 100]).json();
  // cast to int result
  Result<int> intResult = jr.casted();
  // to list result
  Result<List<int>> listResult = jr.mapList((e) => e as int);
```
* map value on success.
```dart  
class Product {
  Map<String, dynamic> model;

  Product(this.model);

  int get id => model["id"];

  String get name => model["name"];
}

Result jr = await httpGet(uri, args: ["pruductId" >> 100]).json();
switch (jr) {
  case Success ok:
  // one model
  Product p = ok.model(Product.new);
  // list model
  List<Product> products = ok.listModel(Product.new);
  break;
  case Failure _:
  break;
}

```
