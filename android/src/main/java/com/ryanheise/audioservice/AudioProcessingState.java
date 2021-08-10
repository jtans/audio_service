package com.ryanheise.audioservice;

public enum AudioProcessingState {
    none,
    connecting,
    buffering,
    ready,
    playing,
    pause,
    fastForwarding,
    rewinding,
    skippingToPrevious,
    skippingToNext,
    skippingToQueueItem,
    completed,
    stopped,
    error,
}
