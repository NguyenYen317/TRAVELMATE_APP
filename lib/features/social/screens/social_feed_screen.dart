import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';
import '../../auth/auth_service.dart';
import '../../auth/provider/auth_provider.dart';
import '../../trip/models/trip_models.dart';
import '../../trip/providers/trip_planner_provider.dart';
import '../models/social_models.dart';
import '../providers/social_provider.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final TextEditingController _postController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final auth = context.read<AuthProvider>();
      context.read<SocialProvider>().loadInitial(userId: auth.currentUser?.id);
    });
  }

  @override
  void dispose() {
    _postController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<SocialProvider, AuthProvider, TripPlannerProvider>(
      builder: (context, socialProvider, authProvider, tripProvider, _) {
        final user = authProvider.currentUser;
        final posts = socialProvider.posts;
        final suggestions = _buildSuggestionPosts(tripProvider.trips);

        return Scaffold(
          appBar: AppBar(title: const Text('AI gợi ý')),
          body: RefreshIndicator(
            onRefresh: () => socialProvider.loadInitial(userId: user?.id),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              itemCount:
                  1 +
                  suggestions.length +
                  posts.length +
                  (socialProvider.isLoadingMore || socialProvider.hasMore
                      ? 1
                      : 0),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildComposer(context, socialProvider, user);
                }

                final suggestionIndex = index - 1;
                if (suggestionIndex < suggestions.length) {
                  return _SuggestionCard(
                    suggestion: suggestions[suggestionIndex],
                  );
                }

                final postIndex = suggestionIndex - suggestions.length;
                if (postIndex < posts.length) {
                  final post = posts[postIndex];
                  return _PostCard(
                    post: post,
                    isLikedByMe: socialProvider.isLikedByMe(post.id),
                    onLikeTap: () {
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Vui lòng đăng nhập để thích bài viết.',
                            ),
                          ),
                        );
                        return;
                      }
                      socialProvider.toggleLike(postId: post.id, user: user);
                    },
                    onCommentTap: () {
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng đăng nhập để bình luận.'),
                          ),
                        );
                        return;
                      }
                      _showComments(context, post, user);
                    },
                  );
                }

                if (socialProvider.isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposer(
    BuildContext context,
    SocialProvider provider,
    AuthUser? user,
  ) {
    if (user == null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bạn chưa đăng nhập',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bạn vẫn xem được bài gợi ý theo chuyến đi. Đăng nhập để post/like/comment.',
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.login);
                },
                child: const Text('Đăng nhập ngay'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đăng bài mới',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _postController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Bạn đang nghĩ gì về chuyến đi của mình?',
                border: OutlineInputBorder(),
              ),
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FutureBuilder<Uint8List>(
                  future: _selectedImage!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container(
                        height: 120,
                        alignment: Alignment.center,
                        color: Colors.black12,
                        child: const CircularProgressIndicator(),
                      );
                    }
                    return Image.memory(
                      snapshot.data!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: provider.isCreatingPost
                      ? null
                      : () async {
                          final image = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          if (!mounted || image == null) {
                            return;
                          }
                          setState(() {
                            _selectedImage = image;
                          });
                        },
                  icon: const Icon(Icons.photo_library_outlined),
                ),
                IconButton(
                  onPressed: provider.isCreatingPost
                      ? null
                      : () async {
                          final image = await _picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                          );
                          if (!mounted || image == null) {
                            return;
                          }
                          setState(() {
                            _selectedImage = image;
                          });
                        },
                  icon: const Icon(Icons.photo_camera_outlined),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: provider.isCreatingPost
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await provider.createPost(
                              user: user,
                              content: _postController.text,
                              imageFile: _selectedImage,
                            );
                            if (!mounted) {
                              return;
                            }
                            _postController.clear();
                            setState(() {
                              _selectedImage = null;
                            });
                          } catch (error) {
                            if (!mounted) {
                              return;
                            }
                            messenger.showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        },
                  child: provider.isCreatingPost
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Post'),
                ),
              ],
            ),
            if (provider.error != null) ...[
              const SizedBox(height: 6),
              Text(
                provider.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showComments(
    BuildContext context,
    SocialPost post,
    AuthUser user,
  ) async {
    final commentController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Consumer<SocialProvider>(
          builder: (context, provider, _) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 12,
              ),
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bình luận',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: StreamBuilder<List<SocialComment>>(
                        stream: provider.watchComments(post.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final items =
                              snapshot.data ?? const <SocialComment>[];
                          if (items.isEmpty) {
                            return const Center(
                              child: Text('Chưa có bình luận.'),
                            );
                          }

                          return ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 8),
                            itemBuilder: (context, index) {
                              final comment = items[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(comment.userName),
                                subtitle: Text(comment.text),
                                trailing: Text(
                                  _fmtDate(comment.createdAt),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: const InputDecoration(
                              hintText: 'Viết bình luận...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            try {
                              await provider.addComment(
                                postId: post.id,
                                user: user,
                                text: commentController.text,
                              );
                              commentController.clear();
                            } catch (error) {
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          },
                          child: const Text('Gửi'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    commentController.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final threshold = _scrollController.position.maxScrollExtent * 0.8;
    if (_scrollController.position.pixels < threshold) {
      return;
    }

    final auth = context.read<AuthProvider>();
    context.read<SocialProvider>().loadMore(userId: auth.currentUser?.id);
  }

  List<_SuggestionPost> _buildSuggestionPosts(List<Trip> trips) {
    final places = <String>{};

    for (final trip in trips) {
      final titleKeywords = _extractKeywords(trip.title);
      places.addAll(titleKeywords);
      for (final location in trip.locations) {
        if (location.name.trim().isNotEmpty) {
          places.add(_normalizePlace(location.name));
        }
      }
    }

    final results = <_SuggestionPost>[];
    for (final place in places) {
      final normalized = _normalizePlace(place);
      if (normalized.isEmpty) {
        continue;
      }
      results.addAll(_suggestionsForPlace(normalized));
      if (results.length >= 18) {
        break;
      }
    }

    if (results.isEmpty) {
      results.add(
        const _SuggestionPost(
          place: 'Điểm đến',
          category: 'Gợi ý',
          title: 'Thêm lịch trình để nhận gợi ý cộng đồng',
          body:
              'Khi bạn tạo chuyến đi trong tab Chuyến đi, cộng đồng sẽ tự gợi ý điểm đẹp, món ăn và văn hóa địa phương.',
        ),
      );
    }

    return results;
  }

  List<String> _extractKeywords(String text) {
    final cleaned = text
        .replaceAll(
          RegExp(r'\d+\s*(ngày|ngay|đêm|dem|n\d+d\d*)', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\d+'), '')
        .trim();

    final parts = cleaned.split(RegExp(r'[,/&\-|và]+', caseSensitive: false));

    return parts
        .map((item) => _normalizePlace(item))
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<_SuggestionPost> _suggestionsForPlace(String place) {
    final lower = place.toLowerCase();

    if (lower.contains('đà nẵng') || lower.contains('da nang')) {
      return const [
        _SuggestionPost(
          place: 'Đà Nẵng',
          category: 'Địa điểm đẹp',
          title: 'Top view đẹp ở Đà Nẵng',
          body:
              'Bán đảo Sơn Trà, Bà Nà Hills, biển Mỹ Khê và cầu Rồng là các điểm check-in nổi bật.',
        ),
        _SuggestionPost(
          place: 'Đà Nẵng',
          category: 'Món ăn',
          title: 'Ăn gì ở Đà Nẵng?',
          body:
              'Mì Quảng, bún chả cá, bánh tráng cuốn thịt heo và hải sản ven biển là lựa chọn đáng thử.',
        ),
        _SuggestionPost(
          place: 'Đà Nẵng',
          category: 'Văn hóa',
          title: 'Nhịp sống địa phương Đà Nẵng',
          body:
              'Người dân thân thiện, không khí biển thoáng, thích hợp dậy sớm dạo biển và khám phá chợ địa phương.',
        ),
      ];
    }

    if (lower.contains('nam định') || lower.contains('nam dinh')) {
      return const [
        _SuggestionPost(
          place: 'Nam Định',
          category: 'Địa điểm đẹp',
          title: 'Gợi ý điểm tham quan Nam Định',
          body:
              'Nhà thờ đổ Hải Lý, biển Thịnh Long, đền Trần và các làng nghề truyền thống rất đáng ghé.',
        ),
        _SuggestionPost(
          place: 'Nam Định',
          category: 'Món ăn',
          title: 'Đặc sản Nam Định nên thử',
          body:
              'Phở bò Nam Định, bánh xíu páo và các món hải sản vùng biển là những món nổi bật.',
        ),
        _SuggestionPost(
          place: 'Nam Định',
          category: 'Văn hóa',
          title: 'Văn hóa lễ hội Nam Định',
          body:
              'Nam Định nổi tiếng với không gian làng quê Bắc Bộ và các lễ hội truyền thống giàu bản sắc.',
        ),
      ];
    }

    return [
      _SuggestionPost(
        place: place,
        category: 'Địa điểm đẹp',
        title: 'Gợi ý cảnh đẹp tại $place',
        body:
            'Ưu tiên khu trung tâm, chợ địa phương, bờ biển/sông/hồ và các điểm cao để ngắm toàn cảnh.',
      ),
      _SuggestionPost(
        place: place,
        category: 'Món ăn',
        title: 'Ăn gì khi đến $place?',
        body:
            'Hãy thử món đặc sản địa phương, quán lâu năm đông khách bản địa và khu ẩm thực buổi tối.',
      ),
      _SuggestionPost(
        place: place,
        category: 'Văn hóa',
        title: 'Trải nghiệm văn hóa tại $place',
        body:
            'Ghé chợ truyền thống, bảo tàng và khu sinh hoạt cộng đồng để hiểu nhịp sống người dân.',
      ),
    ];
  }

  String _normalizePlace(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[,.;:\-\s]+|[,.;:\-\s]+$'), '')
        .trim();
  }

  String _fmtDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.isLikedByMe,
    required this.onLikeTap,
    required this.onCommentTap,
  });

  final SocialPost post;
  final bool isLikedByMe;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: post.userAvatar != null
                      ? NetworkImage(post.userAvatar!)
                      : null,
                  child: post.userAvatar == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _fmtDate(post.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (post.content.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(post.content),
            ],
            if (post.imageUrl != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 120,
                    alignment: Alignment.center,
                    color: Colors.black12,
                    child: const Text('Không tải được ảnh'),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: onLikeTap,
                  icon: Icon(
                    isLikedByMe ? Icons.favorite : Icons.favorite_border,
                    color: isLikedByMe ? Colors.red : null,
                  ),
                ),
                Text('${post.likeCount}'),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: onCommentTap,
                  icon: const Icon(Icons.mode_comment_outlined),
                ),
                Text('${post.commentCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}

class _SuggestionPost {
  const _SuggestionPost({
    required this.place,
    required this.category,
    required this.title,
    required this.body,
  });

  final String place;
  final String category;
  final String title;
  final String body;
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion});

  final _SuggestionPost suggestion;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: color.primary),
                const SizedBox(width: 6),
                Text(
                  'Gợi ý cho ${suggestion.place}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(suggestion.category),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(suggestion.body),
          ],
        ),
      ),
    );
  }
}
