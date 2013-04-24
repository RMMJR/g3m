//
//  CachedDownloader.cpp
//  G3MiOSSDK
//
//  Created by Diego Gomez Deck on 15/08/12.
//
//

#include "CachedDownloader.hpp"
#include "IBufferDownloadListener.hpp"
#include "IImageDownloadListener.hpp"
#include "IStringBuilder.hpp"
#include "ILogger.hpp"
#include "IStorage.hpp"
#include "TimeInterval.hpp"
#include "IFactory.hpp"


class BufferSaverDownloadListener : public IBufferDownloadListener {
private:
  CachedDownloader*        _downloader;
  IBufferDownloadListener* _listener;
  const bool               _deleteListener;
  IStorage*                _storage;
#ifdef C_CODE
  const TimeInterval       _timeToCache;
#endif
#ifdef JAVA_CODE
  private final TimeInterval _timeToCache;
#endif

public:
  BufferSaverDownloadListener(CachedDownloader* downloader,
                              IBufferDownloadListener* listener,
                              bool deleteListener,
                              IStorage* storage,
                              const TimeInterval& timeToCache) :
  _downloader(downloader),
  _listener(listener),
  _deleteListener(deleteListener),
  _storage(storage),
  _timeToCache(timeToCache)
  {

  }

  void deleteListener() {
    if (_deleteListener) {
      delete _listener;
      _listener = NULL;
    }
  }

  void saveBuffer(const URL& url,
                  const IByteBuffer* buffer) {
    if (!url.isFileProtocol()) {
      if (buffer != NULL) {
        if (_storage->isAvailable()) {
          _downloader->countSave();

          _storage->saveBuffer(url, buffer, _timeToCache, _downloader->saveInBackground());
        }
        else {
          ILogger::instance()->logWarning("The cacheStorage is not available, skipping buffer save.");
        }
      }
    }
  }

  void onDownload(const URL& url,
                  IByteBuffer* data) {
    saveBuffer(url, data);

    _listener->onDownload(url, data);

    deleteListener();
  }

  void onError(const URL& url) {
    _listener->onError(url);

    deleteListener();
  }

  void onCanceledDownload(const URL& url,
                          IByteBuffer* buffer) {
    saveBuffer(url, buffer);

    _listener->onCanceledDownload(url, buffer);

    // no deleteListener() call, onCanceledDownload() is always called before onCancel().
  }

  void onCancel(const URL& url) {
    _listener->onCancel(url);

    deleteListener();
  }

};

class ImageSaverDownloadListener : public IImageDownloadListener {
private:
  CachedDownloader* _downloader;

  IImage* _expiredImage;

  IImageDownloadListener* _listener;
  const bool _deleteListener;

  IStorage* _storage;

#ifdef C_CODE
  const TimeInterval _timeToCache;
#endif
#ifdef JAVA_CODE
  private final TimeInterval _timeToCache;
#endif

public:
  ImageSaverDownloadListener(CachedDownloader* downloader,
                             IImage* expiredImage,
                             IImageDownloadListener* listener,
                             bool deleteListener,
                             IStorage* storage,
                             const TimeInterval& timeToCache) :
  _downloader(downloader),
  _expiredImage(expiredImage),
  _listener(listener),
  _deleteListener(deleteListener),
  _storage(storage),
  _timeToCache(timeToCache)
  {

  }

  void deleteListener() {
    if (_deleteListener) {
      delete _listener;
      _listener = NULL;
    }
  }

  ~ImageSaverDownloadListener() {
    delete _expiredImage;
  }

  void saveImage(const URL& url,
                 const IImage* image) {
    if (!url.isFileProtocol()) {
      if (image != NULL) {
        if (_storage->isAvailable()) {
          _downloader->countSave();

          _storage->saveImage(url, image, _timeToCache, _downloader->saveInBackground());
        }
        else {
          ILogger::instance()->logWarning("The cacheStorage is not available, skipping image save.");
        }
      }
    }
  }

  void onDownload(const URL& url,
                  IImage* image,
                  bool expired) {
    if (!expired) {
      saveImage(url, image);
    }

    _listener->onDownload(url, image, expired);

    deleteListener();
  }

  void onError(const URL& url) {
    if (_expiredImage == NULL) {
      _listener->onError(url);
    }
    else {
      _listener->onDownload(url, _expiredImage, true);
      _expiredImage = NULL;
    }

    deleteListener();
  }

  void onCanceledDownload(const URL& url,
                          IImage* image,
                          bool expired) {
    if (!expired) {
      saveImage(url, image);
    }

    _listener->onCanceledDownload(url, image, expired);

    // no deleteListener() call, onCanceledDownload() is always called before onCancel().
  }

  void onCancel(const URL& url) {
    _listener->onCancel(url);

    deleteListener();
  }

};

CachedDownloader::~CachedDownloader() {
  delete _downloader;

  //  if (_lastImage != NULL) {
  //    IFactory::instance()->deleteImage(_lastImage);
  //  }
  if (_lastImageResult != NULL) {
    IFactory::instance()->deleteImage(_lastImageResult->getImage());
    delete _lastImageResult;
  }
  delete _lastImageURL;
}

void CachedDownloader::start() {
  _downloader->start();
}

void CachedDownloader::stop() {
  _downloader->stop();
}

void CachedDownloader::cancelRequest(long long requestId) {
  _downloader->cancelRequest(requestId);
}
long long CachedDownloader::requestBuffer(const URL& url,
                                          long long priority,
                                          const TimeInterval& timeToCache,
                                          IBufferDownloadListener* listener,
                                          bool deleteListener) {
  _requestsCounter++;

  IByteBuffer* cachedBuffer = _storage->isAvailable() ? _storage->readBuffer(url) : NULL;
  if (cachedBuffer == NULL) {
    // cache miss
    return _downloader->requestBuffer(url,
                                      priority,
                                      TimeInterval::zero(),
                                      new BufferSaverDownloadListener(this,
                                                                      listener,
                                                                      deleteListener,
                                                                      _storage,
                                                                      timeToCache),
                                      true);
  }

  // cache hit
  _cacheHitsCounter++;

  listener->onDownload(url, cachedBuffer);

  if (deleteListener) {
    delete listener;
  }

  return -1;
}

const std::string CachedDownloader::statistics() {
  IStringBuilder *isb = IStringBuilder::newStringBuilder();
  isb->addString("CachedDownloader(cache hits=");
  isb->addInt(_cacheHitsCounter);
  isb->addString("/");
  isb->addInt(_requestsCounter);
  isb->addString(", saves=");
  isb->addInt(_savesCounter);
  isb->addString(", downloader=");
  isb->addString(_downloader->statistics());
  const std::string s = isb->getString();
  delete isb;
  return s;
}

void CachedDownloader::onResume(const G3MContext* context) {
  _downloader->onResume(context);
}

void CachedDownloader::onPause(const G3MContext* context) {
  _downloader->onPause(context);
}

void CachedDownloader::onDestroy(const G3MContext* context) {
  _downloader->onDestroy(context);
}

void CachedDownloader::initialize(const G3MContext* context,
                                  FrameTasksExecutor* frameTasksExecutor) {
  _downloader->initialize(context, frameTasksExecutor);
}


IImageResult CachedDownloader::getCachedImageResult(const URL& url,
                                                    bool readExpired) {
  if ( (_lastImageResult != NULL) && (_lastImageURL != NULL) ) {
    if (_lastImageURL->isEqualsTo(url)) {
      // ILogger::instance()->logInfo("Used chached image for %s", url.description().c_str());
      return IImageResult(_lastImageResult->getImage()->shallowCopy(),
                          _lastImageResult->isExpired());
    }
  }

  IImageResult cachedImageResult = _storage->readImage(url, readExpired);
  IImage* cachedImage = cachedImageResult.getImage();

  if (cachedImage != NULL) {
    if (_lastImageResult != NULL) {
      IFactory::instance()->deleteImage(_lastImageResult->getImage());
      delete _lastImageResult;
    }
    _lastImageResult = new IImageResult(cachedImage->shallowCopy(),
                                        cachedImageResult.isExpired());

    delete _lastImageURL;
    _lastImageURL = new URL(url);
  }

  return IImageResult(cachedImage,
                      cachedImageResult.isExpired());
}

long long CachedDownloader::requestImage(const URL& url,
                                         long long priority,
                                         const TimeInterval& timeToCache,
                                         bool readExpired,
                                         IImageDownloadListener* listener,
                                         bool deleteListener) {
  _requestsCounter++;

  IImageResult cachedImageResult = getCachedImageResult(url, readExpired);
  IImage* cachedImage = cachedImageResult.getImage();

  if (cachedImage != NULL && !cachedImageResult.isExpired()) {
    // cache hit
    _cacheHitsCounter++;

    listener->onDownload(url, cachedImage, false);

    if (deleteListener) {
      delete listener;
    }

    return -1;
  }

  // cache miss
  return _downloader->requestImage(url,
                                   priority,
                                   TimeInterval::zero(),
                                   false,
                                   new ImageSaverDownloadListener(this,
                                                                  cachedImage,
                                                                  listener,
                                                                  deleteListener,
                                                                  _storage,
                                                                  timeToCache),
                                   true);
  
}
