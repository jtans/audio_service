

/// The different buttons on a headset.
enum MediaButton {
  media,
  next,
  previous,
}

/// The actons associated with playing audio.
enum MediaAction {
  stop,
  pause,
  play,
  rewind,
  skipToPrevious,
  skipToNext,
  fastForward,
  setRating,
  seekTo,
  playPause,
  playFromMediaId,
  playFromSearch,
  skipToQueueItem,
  playFromUri,
  prepare,
  prepareFromMediaId,
  prepareFromSearch,
  prepareFromUri,
  setRepeatMode,
  unused_1,
  unused_2,
  setShuffleMode,
  seekBackward,
  seekForward,
}

/// The different states during audio processing.
enum AudioProcessingState {
  none,
  connecting,
  buffering,
  ready,
  fastForwarding,
  rewinding,
  skippingToPrevious,
  skippingToNext,
  skippingToQueueItem,
  completed,
  stopped,
  error,
}

enum RatingStyle {
  /// Indicates a rating style is not supported.
  ///
  /// A Rating will never have this type, but can be used by other classes
  /// to indicate they do not support Rating.
  none,

  /// A rating style with a single degree of rating, "heart" vs "no heart".
  ///
  /// Can be used to indicate the content referred to is a favorite (or not).
  heart,

  /// A rating style for "thumb up" vs "thumb down".
  thumbUpDown,

  /// A rating style with 0 to 3 stars.
  range3stars,

  /// A rating style with 0 to 4 stars.
  range4stars,

  /// A rating style with 0 to 5 stars.
  range5stars,

  /// A rating style expressed as a percentage.
  percentage,
}

enum AudioServiceShuffleMode { none, all, group }

enum AudioServiceRepeatMode { none, one, all, group }

/// The playback state for the audio service which includes a [playing] boolean
/// state, a processing state such as [AudioProcessingState.buffering], the
/// playback position and the currently enabled actions to be shown in the
/// Android notification or the iOS control center.
class PlaybackState {
  /// The audio processing state e.g. [BasicPlaybackState.buffering].
  final AudioProcessingState processingState;

  /// Whether audio is either playing, or will play as soon as
  /// [processingState] is [AudioProcessingState.ready]. A true value should
  /// be broadcast whenever it would be appropriate for UIs to display a pause
  /// or stop button.
  ///
  /// Since [playing] and [processingState] can vary independently, it is
  /// possible distinguish a particular audio processing state while audio is
  /// playing vs paused. For example, when buffering occurs during a seek, the
  /// [processingState] can be [AudioProcessingState.buffering], but alongside
  /// that [playing] can be true to indicate that the seek was performed while
  /// playing, or false to indicate that the seek was performed while paused.
  final bool playing;

  /// The set of actions currently supported by the audio service e.g.
  /// [MediaAction.play].
  final Set<MediaAction> actions;

  /// The playback position at the last update time.
  final Duration position;

  /// The buffered position.
  final Duration bufferedPosition;

  /// The current playback speed where 1.0 means normal speed.
  final double speed;

  /// The time at which the playback position was last updated.
  final DateTime updateTime;

  /// The current repeat mode.
  final AudioServiceRepeatMode repeatMode;

  /// The current shuffle mode.
  final AudioServiceShuffleMode shuffleMode;

  const PlaybackState({
    required this.processingState,
    required this.playing,
    required this.actions,
    required this.position,
    required this.bufferedPosition,
    required this.speed,
    required this.updateTime,
    required this.repeatMode,
    required this.shuffleMode,
  });

  /// The current playback position.
  Duration get currentPosition {
    if (playing && processingState == AudioProcessingState.ready) {
      return Duration(
          milliseconds: (position.inMilliseconds +
              ((DateTime.now().millisecondsSinceEpoch -
                  updateTime.millisecondsSinceEpoch) *
                  speed))
              .toInt());
    } else {
      return position;
    }
  }
}

/// A rating to attach to a MediaItem.
class Rating {
  final RatingStyle _type;
  final dynamic _value;

  const Rating._internal(this._type, this._value);

  /// Create a new heart rating.
  const Rating.newHeartRating(bool hasHeart)
      : this._internal(RatingStyle.heart, hasHeart);

  /// Create a new percentage rating.
  factory Rating.newPercentageRating(double percent) {
    if (percent < 0 || percent > 100) throw ArgumentError();
    return Rating._internal(RatingStyle.percentage, percent);
  }

  /// Create a new star rating.
  factory Rating.newStarRating(RatingStyle starRatingStyle, int starRating) {
    if (starRatingStyle != RatingStyle.range3stars &&
        starRatingStyle != RatingStyle.range4stars &&
        starRatingStyle != RatingStyle.range5stars) {
      throw ArgumentError();
    }
    if (starRating > starRatingStyle.index || starRating < 0)
      throw ArgumentError();
    return Rating._internal(starRatingStyle, starRating);
  }

  /// Create a new thumb rating.
  const Rating.newThumbRating(bool isThumbsUp)
      : this._internal(RatingStyle.thumbUpDown, isThumbsUp);

  /// Create a new unrated rating.
  const Rating.newUnratedRating(RatingStyle ratingStyle)
      : this._internal(ratingStyle, null);

  /// Return the rating style.
  RatingStyle getRatingStyle() => _type;

  /// Returns a percentage rating value greater or equal to 0.0f, or a
  /// negative value if the rating style is not percentage-based, or
  /// if it is unrated.
  double getPercentRating() {
    if (_type != RatingStyle.percentage) return -1;
    if (_value < 0 || _value > 100) return -1;
    return _value ?? -1;
  }

  /// Returns a rating value greater or equal to 0.0f, or a negative
  /// value if the rating style is not star-based, or if it is
  /// unrated.
  int getStarRating() {
    if (_type != RatingStyle.range3stars &&
        _type != RatingStyle.range4stars &&
        _type != RatingStyle.range5stars) return -1;
    return _value ?? -1;
  }

  /// Returns true if the rating is "heart selected" or false if the
  /// rating is "heart unselected", if the rating style is not [heart]
  /// or if it is unrated.
  bool hasHeart() {
    if (_type != RatingStyle.heart) return false;
    return _value ?? false;
  }

  /// Returns true if the rating is "thumb up" or false if the rating
  /// is "thumb down", if the rating style is not [thumbUpDown] or if
  /// it is unrated.
  bool isThumbUp() {
    if (_type != RatingStyle.thumbUpDown) return false;
    return _value ?? false;
  }

  /// Return whether there is a rating value available.
  bool isRated() => _value != null;

  Map<String, dynamic> toRaw() {
    return <String, dynamic>{
      'type': _type.index,
      'value': _value,
    };
  }

  // Even though this should take a Map<String, dynamic>, that makes an error.
  Rating.fromRaw(Map<dynamic, dynamic> raw)
      : this._internal(RatingStyle.values[raw['type']], raw['value']);
}

/// A button to appear in the Android notification, lock screen, Android smart
/// watch, or Android Auto device. The set of buttons you would like to display
/// at any given moment should be set via [AudioServiceBackground.setState].
///
/// Each [MediaControl] button controls a specified [MediaAction]. Only the
/// following actions can be represented as buttons:
///
/// * [MediaAction.stop]
/// * [MediaAction.pause]
/// * [MediaAction.play]
/// * [MediaAction.rewind]
/// * [MediaAction.skipToPrevious]
/// * [MediaAction.skipToNext]
/// * [MediaAction.fastForward]
/// * [MediaAction.playPause]
///
/// Predefined controls with default Android icons and labels are defined as
/// static fields of this class. If you wish to define your own custom Android
/// controls with your own icon resources, you will need to place the Android
/// resources in `android/app/src/main/res`. Here, you will find a subdirectory
/// for each different resolution:
///
/// ```
/// drawable-hdpi
/// drawable-mdpi
/// drawable-xhdpi
/// drawable-xxhdpi
/// drawable-xxxhdpi
/// ```
///
/// You can use [Android Asset
/// Studio](https://romannurik.github.io/AndroidAssetStudio/) to generate these
/// different subdirectories for any standard material design icon.
class MediaControl {
  /// A default control for [MediaAction.stop].
  static final stop = MediaControl(
    androidIcon: 'drawable/audio_service_stop',
    label: 'Stop',
    action: MediaAction.stop,
  );

  /// A default control for [MediaAction.pause].
  static final pause = MediaControl(
    androidIcon: 'drawable/audio_service_pause',
    label: 'Pause',
    action: MediaAction.pause,
  );

  /// A default control for [MediaAction.play].
  static final play = MediaControl(
    androidIcon: 'drawable/audio_service_play_arrow',
    label: 'Play',
    action: MediaAction.play,
  );

  /// A default control for [MediaAction.rewind].
  static final rewind = MediaControl(
    androidIcon: 'drawable/audio_service_fast_rewind',
    label: 'Rewind',
    action: MediaAction.rewind,
  );

  /// A default control for [MediaAction.skipToNext].
  static final skipToNext = MediaControl(
    androidIcon: 'drawable/audio_service_skip_next',
    label: 'Next',
    action: MediaAction.skipToNext,
  );

  /// A default control for [MediaAction.skipToPrevious].
  static final skipToPrevious = MediaControl(
    androidIcon: 'drawable/audio_service_skip_previous',
    label: 'Previous',
    action: MediaAction.skipToPrevious,
  );

  /// A default control for [MediaAction.fastForward].
  static final fastForward = MediaControl(
    androidIcon: 'drawable/audio_service_fast_forward',
    label: 'Fast Forward',
    action: MediaAction.fastForward,
  );

  /// A reference to an Android icon resource for the control (e.g.
  /// `"drawable/ic_action_pause"`)
  final String androidIcon;

  /// A label for the control
  final String label;

  /// The action to be executed by this control
  final MediaAction action;

  const MediaControl({
    required this.androidIcon,
    required this.label,
    required this.action,
  });
}

class QueueState {
  final List<MediaItem>? queue;
  final MediaItem? mediaItem;

  QueueState(this.queue, this.mediaItem);
}

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}

///---------------------------- 音频媒体资源 --------------------------------///

/// Provides access to a library of audio.media items. In your app, this could come
/// from a database or web service.
class MediaLibrary {
  final _items = <MediaItem>[
    MediaItem(
      // This can be any unique id, but we use the audio URL for convenience.
      id: "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3",
      album: "Science Friday",
      title: "A Salute To Head-Scratching Science",
      artist: "Science Friday and WNYC Studios",
      duration: Duration(milliseconds: 5739820),
      artUri: Uri.parse(
          "https://audio.media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg"),
    ),
    MediaItem(
      id: "https://s3.amazonaws.com/scifri-segments/scifri201711241.mp3",
      album: "Science Friday",
      title: "From Cat Rheology To Operatic Incompetence",
      artist: "Science Friday and WNYC Studios",
      duration: Duration(milliseconds: 2856950),
      artUri: Uri.parse(
          "https://audio.media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg"),
    ),
  ];

  List<MediaItem> get items => _items;
}

/// Metadata about an audio item that can be played, or a folder containing
/// audio items.
class MediaItem {
  /// A unique id.
  final String id;

  /// The album this audio.media item belongs to.
  final String album;

  /// The title of this audio.media item.
  final String title;

  /// The artist of this audio.media item.
  final String? artist;

  /// The genre of this audio.media item.
  final String? genre;

  /// The duration of this audio.media item.
  final Duration? duration;

  /// The artwork for this audio.media item as a uri.
  final Uri? artUri;

  /// Whether this is playable (i.e. not a folder).
  final bool? playable;

  /// Override the default title for display purposes.
  final String? displayTitle;

  /// Override the default subtitle for display purposes.
  final String? displaySubtitle;

  /// Override the default description for display purposes.
  final String? displayDescription;

  /// The rating of the MediaItem.
  final Rating? rating;

  /// A map of additional metadata for the audio.media item.
  ///
  /// The values must be integers or strings.
  final Map<String, dynamic>? extras;

  /// Creates a [MediaItem].
  ///
  /// [id], [album] and [title] must not be null, and [id] must be unique for
  /// each instance.
  const MediaItem({
    required this.id,
    required this.album,
    required this.title,
    this.artist,
    this.genre,
    this.duration,
    this.artUri,
    this.playable = true,
    this.displayTitle,
    this.displaySubtitle,
    this.displayDescription,
    this.rating,
    this.extras,
  });

  /// Creates a [MediaItem] from a map of key/value pairs corresponding to
  /// fields of this class.
  factory MediaItem.fromJson(Map raw) => MediaItem(
    id: raw['id'],
    album: raw['album'],
    title: raw['title'],
    artist: raw['artist'],
    genre: raw['genre'],
    duration: raw['duration'] != null
        ? Duration(milliseconds: raw['duration'])
        : null,
    artUri: raw['artUri'] != null ? Uri.parse(raw['artUri']) : null,
    playable: raw['playable'],
    displayTitle: raw['displayTitle'],
    displaySubtitle: raw['displaySubtitle'],
    displayDescription: raw['displayDescription'],
    rating: raw['rating'] != null ? Rating.fromRaw(raw['rating']) : null,
    extras: raw['extras']?.cast<String, dynamic>(),
  );

  /// Creates a copy of this [MediaItem] but with with the given fields
  /// replaced by new values.
  MediaItem copyWith({
    String? id,
    String? album,
    String? title,
    String? artist,
    String? genre,
    Duration? duration,
    Uri? artUri,
    bool? playable,
    String? displayTitle,
    String? displaySubtitle,
    String? displayDescription,
    Rating? rating,
    Map<String, dynamic>? extras,
  }) =>
      MediaItem(
        id: id ?? this.id,
        album: album ?? this.album,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        genre: genre ?? this.genre,
        duration: duration ?? this.duration,
        artUri: artUri ?? this.artUri,
        playable: playable ?? this.playable,
        displayTitle: displayTitle ?? this.displayTitle,
        displaySubtitle: displaySubtitle ?? this.displaySubtitle,
        displayDescription: displayDescription ?? this.displayDescription,
        rating: rating ?? this.rating,
        extras: extras ?? this.extras,
      );

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(dynamic other) => other is MediaItem && other.id == id;

  @override
  String toString() => '${toJson()}';

  /// Converts this [MediaItem] to a map of key/value pairs corresponding to
  /// the fields of this class.
  Map<String, dynamic> toJson() => {
    'id': id,
    'album': album,
    'title': title,
    'artist': artist,
    'genre': genre,
    'duration': duration?.inMilliseconds,
    'artUri': artUri?.toString(),
    'playable': playable,
    'displayTitle': displayTitle,
    'displaySubtitle': displaySubtitle,
    'displayDescription': displayDescription,
    'rating': rating?.toRaw(),
    'extras': extras,
  };
}