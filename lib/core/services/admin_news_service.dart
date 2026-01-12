import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/admin_news_item.dart';

class AdminNewsService {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('admin_news');

  /// جلب كل الأخبار (لوحة التحكم)
  Stream<List<AdminNewsItem>> streamAllNews() {
    return _collection.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) =>
              snapshot.docs.map((e) => AdminNewsItem.fromDoc(e)).toList(),
        );
  }

  /// إضافة خبر جديد
  Future<void> addNews(AdminNewsItem item) async {
    await _collection.add(item.toMap());
  }

  /// تحديث خبر
  Future<void> updateNews(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }

  /// حذف خبر
  Future<void> deleteNews(String id) async {
    await _collection.doc(id).delete();
  }

  /// تفعيل / إيقاف
  Future<void> toggleActive(String id, bool value) async {
    await _collection.doc(id).update({'isActive': value});
  }
}
