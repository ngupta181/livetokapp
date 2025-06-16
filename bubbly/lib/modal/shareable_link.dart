class ShareableLink {
  final String shareUrl;
  final String? postThumbnail;
  final String? postDescription;

  ShareableLink({
    required this.shareUrl,
    this.postThumbnail,
    this.postDescription,
  });

  factory ShareableLink.fromJson(Map<String, dynamic> json) {
    return ShareableLink(
      shareUrl: json['share_url'] ?? json['shareUrl'] ?? '',  // Handle both formats
      postThumbnail: json['post_thumbnail'] ?? json['postThumbnail'],
      postDescription: json['post_description'] ?? json['postDescription'],
    );
  }

  @override
  String toString() {
    return 'ShareableLink{shareUrl: $shareUrl, postThumbnail: $postThumbnail, postDescription: $postDescription}';
  }
} 