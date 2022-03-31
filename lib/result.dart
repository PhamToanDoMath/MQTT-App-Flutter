class Result {
  final String result;

  Result(this.result);

  Result.fromJson(Map<String, dynamic> json)
      : result = json['result'][0];

}
