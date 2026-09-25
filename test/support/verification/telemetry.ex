defmodule PhoenixTest.Verification.Telemetry do
  @moduledoc false

  alias PhoenixTest.Verification.Recorder
  alias PhoenixTest.WebApp.VerificationController
  alias PhoenixTest.WebApp.VerificationLive

  def attach! do
    :ok =
      :telemetry.attach_many(
        {__MODULE__, :observations},
        [
          [:phoenix, :live_view, :handle_event, :stop],
          [:phoenix, :router_dispatch, :stop]
        ],
        &__MODULE__.handle_event/4,
        nil
      )
  end

  def handle_event(
        [:phoenix, :live_view, :handle_event, :stop],
        _measurements,
        %{
          socket: %{view: VerificationLive, assigns: %{run_id: run_id, uploads: %{photos: photos}}},
          event: "upload_save",
          params: params
        },
        _config
      ) do
    entries =
      Enum.map(photos.entries, fn entry ->
        %{filename: entry.client_name, content_type: entry.client_type, size: entry.client_size}
      end)

    Recorder.record(run_id, %{event: "upload_save", params: Map.drop(params, ["photos"]), uploads: entries})
  end

  def handle_event(
        [:phoenix, :live_view, :handle_event, :stop],
        _measurements,
        %{socket: %{view: VerificationLive, assigns: %{run_id: run_id}}, event: event, params: params},
        _config
      ) do
    Recorder.record(run_id, %{event: event, params: params})
  end

  def handle_event(
        [:phoenix, :router_dispatch, :stop],
        _measurements,
        %{
          conn: %Plug.Conn{
            private: %{phoenix_controller: VerificationController, phoenix_action: :submit},
            method: method,
            params: %{"run_id" => run_id} = params
          }
        },
        _config
      ) do
    Recorder.record(run_id, %{method: method, params: params})
  end

  def handle_event(
        [:phoenix, :router_dispatch, :stop],
        _measurements,
        %{
          conn: %Plug.Conn{
            private: %{phoenix_controller: VerificationController, phoenix_action: :get_submit},
            method: method,
            request_path: path,
            params: %{"run_id" => run_id} = params
          }
        },
        _config
      ) do
    Recorder.record(run_id, %{method: method, path: path, params: params})
  end

  def handle_event(
        [:phoenix, :router_dispatch, :stop],
        _measurements,
        %{
          conn: %Plug.Conn{
            private: %{phoenix_controller: VerificationController, phoenix_action: :override_submit},
            method: method,
            params: %{"run_id" => run_id} = params
          }
        },
        _config
      ) do
    Recorder.record(run_id, %{method: method, params: params})
  end

  def handle_event(
        [:phoenix, :router_dispatch, :stop],
        _measurements,
        %{
          conn: %Plug.Conn{
            private: %{phoenix_controller: VerificationController, phoenix_action: :submitter_submit},
            method: method,
            request_path: path,
            params: %{"run_id" => run_id} = params
          }
        },
        _config
      ) do
    Recorder.record(run_id, %{method: method, path: path, params: params})
  end

  def handle_event(
        [:phoenix, :router_dispatch, :stop],
        _measurements,
        %{
          conn: %Plug.Conn{
            private: %{phoenix_controller: VerificationController, phoenix_action: :upload_submit},
            method: method,
            params: %{"run_id" => run_id} = params
          }
        },
        _config
      ) do
    Recorder.record(run_id, %{method: method, params: stable_uploads(params)})
  end

  def handle_event(_event, _measurements, _metadata, _config), do: :ok

  defp stable_uploads(%Plug.Upload{} = upload) do
    %{filename: upload.filename, content_type: upload.content_type, size: File.stat!(upload.path).size}
  end

  defp stable_uploads(list) when is_list(list), do: Enum.map(list, &stable_uploads/1)
  defp stable_uploads(map) when is_map(map), do: Map.new(map, fn {key, value} -> {key, stable_uploads(value)} end)
  defp stable_uploads(value), do: value
end
