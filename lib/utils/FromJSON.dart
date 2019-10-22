class FromStatus {
  final  String status;
  final  String token;
  FromStatus({this.status,this.token});
  factory FromStatus.fromJson(Map<String,dynamic> json){
    return FromStatus(
      status:json['status'],
      token: json['access_token']
    );
  }
}

class FromMember {
  final String id;
  final String name;
  final String email;
  final int point;
  final String provider_pic;
  final bool post_permission;
  FromMember({this.id,this.name,this.email,this.point,this.provider_pic,this.post_permission});
  factory FromMember.fromJson(Map<String,dynamic> json){
    print(json['post_permission']);
    return FromMember(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      point: json['point'],
      provider_pic: json['provider_pic'],
      post_permission: json['post_permission']
    );
  }
}
class MembersList {
  final List<Member> members;

  MembersList({
    this.members,
});

  factory MembersList.fromJson(List<dynamic> parsedJson) {

    List<Member> members = new List<Member>();
    members = parsedJson.map((i)=>Member.fromJson(i)).toList();

    return new MembersList(
      members: members
    );
  }
}

class Member{
  final String id;
  final String name;
  final String email;
  final int point;
  final String provider_pic;
  final bool post_permission;

  Member({
    this.id,
    this.name,
    this.email,
    this.point,
    this.provider_pic,
    this.post_permission
}) ;

  factory Member.fromJson(Map<String, dynamic> json){
    return new Member(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      point: int.parse(json['point']),
      provider_pic: json['provider_pic'],
      post_permission: json['post_permission']
    );
  }

}