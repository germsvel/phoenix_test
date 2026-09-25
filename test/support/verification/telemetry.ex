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

  def handle_event(_event, _measurements, _metadata, _config), do: :ok
end
