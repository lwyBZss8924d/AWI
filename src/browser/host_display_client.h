#ifndef CARBONYL_SRC_BROWSER_HOST_DISPLAY_CLIENT_H_
#define CARBONYL_SRC_BROWSER_HOST_DISPLAY_CLIENT_H_

#include <memory>

#include "base/callback.h"
#include "base/memory/shared_memory_mapping.h"
#include "carbonyl/src/browser/export.h"
#include "components/viz/host/host_display_client.h"
#include "services/viz/privileged/mojom/compositing/layered_window_updater.mojom.h"
#include "ui/gfx/native_widget_types.h"

namespace carbonyl {

typedef base::RepeatingCallback<void(const gfx::Rect&, const SkBitmap&)>
    OnPaintCallback;

class CARBONYL_VIZ_EXPORT LayeredWindowUpdater : public viz::mojom::LayeredWindowUpdater {
 public:
  explicit LayeredWindowUpdater(
      mojo::PendingReceiver<viz::mojom::LayeredWindowUpdater> receiver);
  ~LayeredWindowUpdater() override;

  // disable copy
  LayeredWindowUpdater(const LayeredWindowUpdater&) = delete;
  LayeredWindowUpdater& operator=(const LayeredWindowUpdater&) = delete;

  // viz::mojom::LayeredWindowUpdater implementation.
  void OnAllocatedSharedMemory(const gfx::Size& pixel_size,
                               base::UnsafeSharedMemoryRegion region) override;
  void Draw(const gfx::Rect& damage_rect, DrawCallback draw_callback) override;

 private:
  mojo::Receiver<viz::mojom::LayeredWindowUpdater> receiver_;
  base::WritableSharedMemoryMapping shm_mapping_;
  gfx::Size pixel_size_;
  DrawCallback callback_;
  scoped_refptr<base::SingleThreadTaskRunner> task_runner_;
  base::WeakPtrFactory<LayeredWindowUpdater> weak_ptr_factory_ { this };
};

class CARBONYL_VIZ_EXPORT HostDisplayClient : public viz::HostDisplayClient {
 public:
  explicit HostDisplayClient();
  ~HostDisplayClient() override;

  // disable copy
  HostDisplayClient(const HostDisplayClient&) = delete;
  HostDisplayClient& operator=(const HostDisplayClient&) =
      delete;

 private:
#if BUILDFLAG(IS_MAC)
  void OnDisplayReceivedCALayerParams(
      const gfx::CALayerParams& ca_layer_params) override;
#endif

  void CreateLayeredWindowUpdater(
      mojo::PendingReceiver<viz::mojom::LayeredWindowUpdater> receiver)
      override;

#if BUILDFLAG(IS_LINUX) && !BUILDFLAG(IS_CHROMEOS)
  void DidCompleteSwapWithNewSize(const gfx::Size& size) override;
#endif

  std::unique_ptr<LayeredWindowUpdater> layered_window_updater_;
  OnPaintCallback callback_;
};

}  // namespace carbonyl

#endif  // CARBONYL_SRC_BROWSER_HOST_DISPLAY_CLIENT_H_
