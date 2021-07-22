
import 'package:audio_service/audio/media/audio_media_resource.dart';

///音频媒体数据类型转换器
abstract class IAudioMediaTypeConverter<T> {

  T convertRawMapToMediaItem(Map raw);

  List<T> convertRawListToMediaItemList(List rawList);

  List convertMediaItemListToRawList(List<T> mediaItemList);

  Map mediaItemToJson(T mediaItem);

}

class AudioMediaTypeConverter implements IAudioMediaTypeConverter<MediaItem> {
  @override
  MediaItem convertRawMapToMediaItem(Map<dynamic, dynamic> raw) {
    return MediaItem.fromJson(raw);
  }

  @override
  List<MediaItem> convertRawListToMediaItemList(List rawList) {
    return rawList.map((raw) => MediaItem.fromJson(raw)).toList();
  }

  @override
  List convertMediaItemListToRawList(List<MediaItem> mediaItemList) {
    return mediaItemList.map((mediaItem) => mediaItem.toJson()).toList();
  }

  @override
  Map mediaItemToJson(MediaItem mediaItem) {
    return mediaItem.toJson();
  }

}